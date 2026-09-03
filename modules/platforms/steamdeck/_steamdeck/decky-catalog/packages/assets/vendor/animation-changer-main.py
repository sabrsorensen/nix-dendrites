import asyncio
import json
import os
import random
import shutil
import socket
import ssl
import aiohttp
import certifi
from aiohttp import ClientSession, TCPConnector
import decky_plugin

CONFIG_PATH = os.path.join(decky_plugin.DECKY_PLUGIN_SETTINGS_DIR, 'config.json')
ANIMATIONS_PATH = os.path.join(decky_plugin.DECKY_PLUGIN_RUNTIME_DIR, 'animations')
DOWNLOADS_PATH = os.path.join(decky_plugin.DECKY_PLUGIN_RUNTIME_DIR, 'downloads')
OVERRIDE_PATH = os.path.expanduser('~/.steam/root/config/uioverrides/movies')

BOOT_VIDEO = 'deck_startup.webm'
SUSPEND_VIDEO = 'steam_os_suspend.webm'
THROBBER_VIDEO = 'steam_os_suspend_from_throbber.webm'

VIDEOS_NAMES = [BOOT_VIDEO, SUSPEND_VIDEO, THROBBER_VIDEO]
VIDEO_TYPES = ['boot', 'suspend', 'throbber']
VIDEO_TARGETS = ['boot', 'suspend', 'suspend']

NIX_MOVIE_OVERRIDES = {
    'boot': 'boot',
    'suspend': 'suspend',
    'throbber': 'throbber',
    BOOT_VIDEO: 'boot',
    SUSPEND_VIDEO: 'suspend',
    THROBBER_VIDEO: 'throbber',
}

REQUEST_RETRIES = 5

ssl_ctx = ssl.create_default_context(cafile=certifi.where())

config = {}
local_animations = []
local_sets = []
animation_cache = []
unloaded = False


def build_connector():
    connector_args = {}
    if config.get('force_ipv4'):
        connector_args['family'] = socket.AF_INET
    return TCPConnector(**connector_args)


def normalize_nix_movie_override(movie):
    return NIX_MOVIE_OVERRIDES.get(movie)


def build_download_entry(anim_id):
    cached = find_cached_animation(anim_id)
    if cached is not None:
        return cached

    for existing in config.get('downloads', []):
        if existing.get('id') == anim_id:
            return existing

    return {
        'id': anim_id,
        'name': f'Animation {anim_id}',
        'target': 'boot',
        'manifest_version': 1,
    }


def get_nix_animation_ids(nix_config):
    animation_ids = []

    for key in ('download_animation_ids', 'animation_ids'):
        value = nix_config.get(key, [])
        if isinstance(value, list):
            animation_ids.extend(value)

    for override in nix_config.get('movie_overrides', []):
        if not isinstance(override, dict):
            continue
        anim_id = override.get('animation_id', override.get('animationId'))
        if anim_id:
            animation_ids.append(anim_id)

    for key in ('boot_animation', 'suspend_animation', 'throbber_animation'):
        anim_id = nix_config.get(key)
        if anim_id:
            animation_ids.append(anim_id)

    return list(dict.fromkeys(animation_ids))


async def get_steamdeckrepo():
    try:
        for _ in range(REQUEST_RETRIES):
            async with ClientSession(connector=build_connector()) as web:
                async with web.request(
                        'get',
                        f'https://steamdeckrepo.com/api/posts/all',
                        ssl=ssl_ctx
                ) as res:
                    if res.status == 200:
                        data = (await res.json())['posts']
                        break
                    status = res.status
                    if res.status == 429:
                        raise Exception('Rate limit exceeded, try again in a minute')
                    decky_plugin.logger.warning(f'steamdeckrepo fetch failed, status={res.status}')
        else:
            raise Exception(f'Retry attempts exceeded, status code: {status}')
        return [{
            'id': entry['id'],
            'name': entry['title'],
            'preview_image': entry['thumbnail'],
            'preview_video': entry['video'],
            'author': entry['user']['steam_name'],
            'description': entry['content'],
            'last_changed': entry['updated_at'],  # Todo: Ensure consistent date format
            'source': entry['url'],
            'download_url': 'https://steamdeckrepo.com/post/download/' + entry['id'],
            'likes': entry['likes'],
            'downloads': entry['downloads'],
            'version': '',
            'target': 'suspend' if entry['type'] == 'suspend_video' else 'boot',
            'manifest_version': 1
        } for entry in data if entry['type'] in ['suspend_video', 'boot_video']]
    except Exception as e:
        decky_plugin.logger.error('Failed to fetch steamdeckrepo', exc_info=e)
        raise e


async def update_cache():
    global animation_cache
    animation_cache = await get_steamdeckrepo()
    # Todo: JSON URL based sources
    # Todo: How to merge sources with less metadata with steamdeckrepo results gracefully?


async def regenerate_downloads():
    downloads = []
    if len(animation_cache) == 0:
        try:
            await update_cache()
        except Exception:
            pass
    for file in os.listdir(DOWNLOADS_PATH):
        if not file.endswith('.webm'):
            continue
        anim_id = file[:-5]
        downloads.append(build_download_entry(anim_id))
    config['downloads'] = downloads


async def refresh_download_metadata():
    downloads_before = json.dumps(config.get('downloads', []), sort_keys=True)
    await regenerate_downloads()
    downloads_after = json.dumps(config.get('downloads', []), sort_keys=True)
    return downloads_before != downloads_after


async def load_config():
    global config
    config = {
        'boot': '',
        'suspend': '',
        'throbber': '',
        'randomize': '',
        'current_set': '',
        'downloads': [],
        'custom_animations': [],
        'custom_sets': [],
        'shuffle_exclusions': [],
        'force_ipv4': False
    }

    async def save_new():
        try:
            await regenerate_downloads()
            save_config()
        except Exception as ex:
            decky_plugin.logger.error('Failed to save new config', exc_info=ex)

    if os.path.exists(CONFIG_PATH):
        try:
            with open(CONFIG_PATH) as f:
                config.update(json.load(f))
                if type(config['randomize']) == bool:
                    config['randomize'] = ''
        except Exception as e:
            decky_plugin.logger.error('Failed to load config', exc_info=e)
            await save_new()
    else:
        await save_new()


def raise_and_log(msg, ex=None):
    decky_plugin.logger.error(msg, exc_info=ex)
    if ex is None:
        raise Exception(msg)
    raise ex


def save_config():
    try:
        with open(CONFIG_PATH, 'w') as f:
            json.dump(config, f, indent=4)
    except Exception as e:
        raise_and_log('Failed to save config', e)


def load_local_animations():
    global local_animations
    global local_sets

    animations = []
    sets = []
    directories = next(os.walk(ANIMATIONS_PATH))[1]
    for directory in directories:
        is_set = False
        config_path = f'{ANIMATIONS_PATH}/{directory}/config.json'
        anim_config = {}
        if os.path.exists(config_path):
            try:
                with open(config_path) as f:
                    anim_config = json.load(f)
                is_set = True
            except Exception as e:
                decky_plugin.logger.warning(f'Failed to parse config.json for: {directory}', exc_info=e)
        else:
            for video in [BOOT_VIDEO, SUSPEND_VIDEO, THROBBER_VIDEO]:
                if os.path.exists(f'{ANIMATIONS_PATH}/{directory}/{video}'):
                    is_set = True
                    break
        if not is_set:
            continue

        local_set = {
            'id': directory,
            'enabled': anim_config['enabled'] if 'enabled' in anim_config else True
        }

        def process_animation(default, anim_type, target):
            filename = default if anim_type not in anim_config else anim_config[anim_type]
            if anim_type not in anim_config and not os.path.exists(f'{ANIMATIONS_PATH}/{directory}/{filename}'):
                filename = ''
            local_set[anim_type] = filename
            if filename != '' and filename is not None:
                animations.append({
                    'id': f'{directory}/{filename}',
                    'name': directory if anim_type == 'boot' else f'{directory} - {anim_type.capitalize()}',
                    'target': target
                })

        for i in range(3):
            process_animation(VIDEOS_NAMES[i], VIDEO_TYPES[i], VIDEO_TARGETS[i])

        sets.append(local_set)

    local_animations = animations
    local_sets = sets


def find_cached_animation(anim_id):
    for anim in animation_cache:
        if anim['id'] == anim_id:
            return anim
    return None


def find_animation_path(anim_id):
    for anim in config['downloads']:
        if anim['id'] == anim_id:
            return f'{DOWNLOADS_PATH}/{anim_id}.webm'

    for anim in config['custom_animations']:
        if anim['id'] == anim_id:
            return anim['path']

    for anim in local_animations:
        if anim['id'] == anim_id:
            return ANIMATIONS_PATH + '/' + anim_id

    local_download_path = f'{DOWNLOADS_PATH}/{anim_id}.webm'
    if os.path.exists(local_download_path):
        return local_download_path

    return None


def apply_animation(video, anim_id):
    override_path = f'{OVERRIDE_PATH}/{video}'
    if os.path.islink(override_path) or os.path.exists(override_path):
        os.remove(override_path)

    if anim_id == '':
        return

    path = find_animation_path(anim_id)
    if path is None or not os.path.exists(path):
        raise_and_log(f'Failed to find animation for: {anim_id}')

    tmp_override_path = f'{override_path}.tmp'
    if os.path.exists(tmp_override_path):
        os.remove(tmp_override_path)
    shutil.copyfile(path, tmp_override_path)
    os.replace(tmp_override_path, override_path)


def apply_animations():
    for i in range(3):
        apply_animation(VIDEOS_NAMES[i], config[VIDEO_TYPES[i]])


def apply_nix_movie_overrides(nix_config):
    for override in nix_config.get('movie_overrides', []):
        if not isinstance(override, dict):
            continue

        movie = override.get('movie')
        anim_id = override.get('animation_id', override.get('animationId'))
        config_key = normalize_nix_movie_override(movie)

        if config_key is None:
            decky_plugin.logger.warning(f'Ignoring unknown movie override target: {movie}')
            continue
        if not anim_id:
            decky_plugin.logger.warning(f'Ignoring empty movie override for target: {movie}')
            continue

        config[config_key] = anim_id

    legacy_overrides = {
        'boot_animation': 'boot',
        'suspend_animation': 'suspend',
        'throbber_animation': 'throbber',
    }
    for nix_key, config_key in legacy_overrides.items():
        anim_id = nix_config.get(nix_key)
        if anim_id:
            config[config_key] = anim_id

    if 'randomize' in nix_config:
        config['randomize'] = nix_config['randomize']

    if 'force_ipv4' in nix_config:
        config['force_ipv4'] = nix_config['force_ipv4']


async def download_nix_animation(anim_id):
    local_file_path = f'{DOWNLOADS_PATH}/{anim_id}.webm'
    in_config_downloads = any(entry['id'] == anim_id for entry in config['downloads'])

    if os.path.exists(local_file_path):
        if not in_config_downloads:
            config['downloads'].append(build_download_entry(anim_id))
        return True

    if in_config_downloads:
        return True

    if len(animation_cache) == 0:
        decky_plugin.logger.warning(f'Animation cache unavailable; deferring download for {anim_id}')
        return False

    anim = find_cached_animation(anim_id)
    if anim is None:
        decky_plugin.logger.warning(f'Animation {anim_id} not found in cache')
        return False

    async with aiohttp.ClientSession(connector=build_connector()) as web:
        async with web.get(anim['download_url'], ssl=ssl_ctx) as response:
            if response.status != 200:
                decky_plugin.logger.warning(
                    f'Failed to download animation {anim_id}, status={response.status}'
                )
                return False
            data = await response.read()

    with open(local_file_path, 'wb') as f:
        f.write(data)

    config['downloads'].append(anim)
    return True


async def apply_nix_config(nix_config):
    animation_ids = get_nix_animation_ids(nix_config)
    if animation_ids:
        decky_plugin.logger.info(f'Processing {len(animation_ids)} animations from Nix config')

    for anim_id in animation_ids:
        try:
            await download_nix_animation(anim_id)
        except Exception as e:
            decky_plugin.logger.warning(f'Failed to process animation {anim_id}', exc_info=e)

    await refresh_download_metadata()
    apply_nix_movie_overrides(nix_config)
    save_config()


async def retry_nix_animation_downloads_later(nix_config):
    await asyncio.sleep(30.0)
    if unloaded:
        return

    try:
        await update_cache()
        await refresh_download_metadata()
    except Exception as e:
        decky_plugin.logger.warning('Retry cache update failed', exc_info=e)
        return

    changed = False
    for anim_id in get_nix_animation_ids(nix_config):
        try:
            changed = await download_nix_animation(anim_id) or changed
        except Exception as e:
            decky_plugin.logger.warning(f'Failed retry download for {anim_id}', exc_info=e)

    changed = await refresh_download_metadata() or changed
    if changed:
        save_config()
        try:
            apply_animations()
        except Exception as e:
            decky_plugin.logger.warning('Failed to apply animations after retry', exc_info=e)


def get_active_sets():
    return [entry for entry in local_sets + config['custom_sets'] if entry['enabled']]


def remove_custom_set(set_id):
    config['custom_sets'] = [entry for entry in config['custom_sets'] if entry['id'] != set_id]


def remove_custom_animation(anim_id):
    config['custom_animations'] = [anim for anim in config['custom_animations'] if anim['id'] != anim_id]


def randomize_current_set():
    active = get_active_sets()
    new_set = {'boot': '', 'suspend': '', 'throbber': ''}
    if len(active) > 0:
        new_set = active[random.randint(0, len(active) - 1)]
        config['current_set'] = new_set['id']
    for i in range(3):
        config[VIDEO_TYPES[i]] = new_set[VIDEO_TYPES[i]]['id']


def randomize_all():
    for i in range(3):
        pool = [
            anim for anim in local_animations + config['downloads'] + config['custom_animations']
            if anim['target'] == VIDEO_TARGETS[i] and anim['id'] not in config['shuffle_exclusions']
        ]
        if len(pool) > 0:
            config[VIDEO_TYPES[i]] = pool[random.randint(0, len(pool) - 1)]['id']
    config['current_set'] = ''


class Plugin:

    async def getState(self):
        """ Get backend state (animations, sets, and settings) """
        try:
            return {
                'local_animations': local_animations,
                'custom_animations': config['custom_animations'],
                'downloaded_animations': config['downloads'],
                'local_sets': local_sets,
                'custom_sets': config['custom_sets'],
                'settings': {
                    'randomize': config['randomize'],
                    'current_set': config['current_set'],
                    'boot': config['boot'],
                    'suspend': config['suspend'],
                    'throbber': config['throbber'],
                    'shuffle_exclusions': config['shuffle_exclusions'],
                    'force_ipv4': config['force_ipv4']
                }
            }
        except Exception as e:
            decky_plugin.logger.error('Failed to get state', exc_info=e)
            raise e

    async def saveCustomSet(self, set_entry):
        """ Save custom set entry """
        try:
            remove_custom_set(set_entry['id'])
            config['custom_sets'].append(set_entry)
            save_config()
        except Exception as e:
            decky_plugin.logger.error('Failed to save custom set', exc_info=e)
            raise e

    async def removeCustomSet(self, set_id):
        """ Remove custom set """
        try:
            remove_custom_set(set_id)
            save_config()
        except Exception as e:
            decky_plugin.logger.error('Failed to remove custom set', exc_info=e)
            raise e

    async def enableSet(self, set_id, enable):
        """ Enable or disable set """
        try:
            for entry in local_sets:
                if entry['id'] == set_id:
                    entry['enabled'] = enable
                    with open(f'{ANIMATIONS_PATH}/{entry["id"]}/config.json', 'w') as f:
                        json.dump(entry, f, indent=4)
                    return
            for entry in config['custom_sets']:
                if entry['id'] == set_id:
                    entry['enabled'] = enable
                    save_config()
                    break
        except Exception as e:
            decky_plugin.logger.error('Failed to enable set', exc_info=e)
            raise e

    async def saveCustomAnimation(self, anim_entry):
        """ Save a custom animation entry """
        try:
            remove_custom_animation(anim_entry['id'])
            config['custom_animations'].append(anim_entry)
            save_config()
        except Exception as e:
            decky_plugin.logger.error('Failed to save custom animation', exc_info=e)
            raise e

    async def removeCustomAnimation(self, anim_id):
        """ Removes custom animation with name """
        try:
            remove_custom_animation(anim_id)
            save_config()
        except Exception as e:
            decky_plugin.logger.error('Failed to remove custom animation', exc_info=e)
            raise e

    async def updateAnimationCache(self):
        """ Update backend animation cache """
        try:
            await update_cache()
            if await refresh_download_metadata():
                save_config()
            return {'animations': animation_cache}
        except Exception as e:
            decky_plugin.logger.error('Failed to update animation cache', exc_info=e)
            return {'animations': animation_cache}

    async def getCachedAnimations(self):
        """ Get cached repository animations """
        try:
            return {'animations': animation_cache}
        except Exception as e:
            decky_plugin.logger.error('Failed to get cached animations', exc_info=e)
            raise e

    async def getCachedAnimation(self, anim_id):
        """ Get a cached animation entry for id """
        try:
            return find_cached_animation(anim_id)
        except Exception as e:
            decky_plugin.logger.error('Failed to get cached animations', exc_info=e)
            raise e

    async def downloadAnimation(self, anim_id):
        """ Download a cached animation for id """
        try:
            for entry in config['downloads']:
                if entry['id'] == anim_id:
                    return
            async with aiohttp.ClientSession(connector=build_connector()) as web:
                if (anim := find_cached_animation(anim_id)) is None:
                    raise_and_log(f'Failed to find cached animation with id: {id}')
                async with web.get(anim['download_url'], ssl=ssl_ctx) as response:
                    if response.status != 200:
                        raise_and_log(f'Invalid download request status: {response.status}')
                    data = await response.read()
            with open(f'{DOWNLOADS_PATH}/{anim_id}.webm', 'wb') as f:
                f.write(data)
            config['downloads'].append(anim)
            save_config()
        except Exception as e:
            decky_plugin.logger.error('Failed to download animation', exc_info=e)
            raise e

    async def deleteAnimation(self, anim_id):
        """ Delete a downloaded animation """
        try:
            config['downloads'] = [entry for entry in config['downloads'] if entry['id'] != anim_id]
            save_config()
            os.remove(f'{DOWNLOADS_PATH}/{anim_id}.webm')
        except Exception as e:
            decky_plugin.logger.error('Failed to delete animation', exc_info=e)
            raise e

    async def saveSettings(self, settings):
        """ Save settings to config file """
        try:
            config.update(settings)
            save_config()
            apply_animations()
        except Exception as e:
            decky_plugin.logger.error('Failed to save settings', exc_info=e)
            raise e

    async def reloadConfiguration(self):
        """ Reload config file and local animations from disk """
        try:
            await load_config()
            load_local_animations()
            await refresh_download_metadata()
            apply_animations()
        except Exception as e:
            decky_plugin.logger.error('Failed to reload configuration', exc_info=e)
            raise e

    async def randomize(self, shuffle):
        """ Randomize animations """
        try:
            if shuffle:
                randomize_all()
            else:
                randomize_current_set()
            save_config()
            apply_animations()
        except Exception as e:
            decky_plugin.logger.error('Failed to randomize animations', exc_info=e)
            raise e

    async def _main(self):
        decky_plugin.logger.info('Initializing...')

        try:
            os.makedirs(ANIMATIONS_PATH, exist_ok=True)
            os.makedirs(OVERRIDE_PATH, exist_ok=True)
            os.makedirs(os.path.dirname(CONFIG_PATH), exist_ok=True)
            os.makedirs(DOWNLOADS_PATH, exist_ok=True)
        except Exception as e:
            decky_plugin.logger.error('Failed to make plugin directories', exc_info=e)
            raise e

        try:
            await load_config()
            load_local_animations()
            await refresh_download_metadata()
        except Exception as e:
            decky_plugin.logger.error('Failed to load config', exc_info=e)
            raise e

        nix_config = None
        nix_config_path = os.path.join(decky_plugin.DECKY_PLUGIN_DIR, 'nix-animations.json')
        if os.path.exists(nix_config_path):
            try:
                with open(nix_config_path) as f:
                    nix_config = json.load(f)
                decky_plugin.logger.info(
                    f'Loaded Nix animation configuration with {len(get_nix_animation_ids(nix_config))} animation ids'
                )
            except Exception as e:
                decky_plugin.logger.error('Failed to load Nix animation config', exc_info=e)

        try:
            await update_cache()
            if await refresh_download_metadata():
                save_config()
        except Exception as e:
            decky_plugin.logger.warning('Failed to update animation cache; continuing without online cache', exc_info=e)

        if nix_config is not None:
            try:
                await apply_nix_config(nix_config)
            except Exception as e:
                decky_plugin.logger.error('Failed to apply Nix animation configuration', exc_info=e)
            else:
                if get_nix_animation_ids(nix_config) and len(animation_cache) == 0:
                    asyncio.create_task(retry_nix_animation_downloads_later(nix_config))

        try:
            if config['randomize'] == 'all':
                randomize_all()
            elif config['randomize'] == 'set':
                randomize_current_set()
        except Exception as e:
            decky_plugin.logger.error('Failed to randomize animations', exc_info=e)
            raise e

        try:
            apply_animations()
        except Exception as e:
            decky_plugin.logger.error('Failed to apply animations', exc_info=e)
            raise e

        await asyncio.sleep(5.0)
        if unloaded:
            return
        try:
            await update_cache()
            if await refresh_download_metadata():
                save_config()
        except Exception as e:
            decky_plugin.logger.warning('Failed to update animation cache; continuing without online cache', exc_info=e)

        decky_plugin.logger.info('Initialized')

    async def _unload(self):
        global unloaded
        unloaded = True
        decky_plugin.logger.info('Unloaded')

    async def _migration(self):
        decky_plugin.logger.info('Migrating')
        # `/tmp/animation_changer.log` will be migrated to `decky_plugin.DECKY_PLUGIN_LOG_DIR/template.log`
        decky_plugin.migrate_logs('/tmp/animation_changer.log')
        # `~/.config/AnimationChanger/config.json` will be migrated to `decky_plugin.DECKY_PLUGIN_SETTINGS_DIR/config.json`
        decky_plugin.migrate_settings(os.path.expanduser('~/.config/AnimationChanger/config.json'))
        # `~/homebrew/animations` will be migrated to `decky_plugin.DECKY_PLUGIN_RUNTIME_DIR/animations/`
        decky_plugin.migrate_any(ANIMATIONS_PATH, os.path.expanduser('~/homebrew/animations'))
        # `~/.config/AnimationChanger/downloads` will be migrated to `decky_plugin.DECKY_PLUGIN_RUNTIME_DIR/downloads/`
        decky_plugin.migrate_any(DOWNLOADS_PATH, os.path.expanduser('~/.config/AnimationChanger/downloads'))
