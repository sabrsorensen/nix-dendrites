import re

from beets.plugins import BeetsPlugin


FEAT_RE = re.compile(r"\b(?:feat(?:uring)?|ft)\.?\s+", re.IGNORECASE)
SPLIT_RE = re.compile(r"\s*(?:,|;|&|/|\band\b)\s*", re.IGNORECASE)
TRAILING_GROUP_RE = re.compile(r"^(?P<base>.*?)\s*(?P<group>\((?:[^()]*)\)|\[(?:[^\[\]]*)\])\s*$")
REMIX_TOKEN_RE = re.compile(r"\b(remix|rmx|mix)\b", re.IGNORECASE)


def normalize_spaces(value):
    return re.sub(r"\s+", " ", value or "").strip()


def first_non_empty(*values):
    for value in values:
        if normalize_spaces(value):
            return normalize_spaces(value)
    return ""


def normalize_feat_keyword(value):
    return FEAT_RE.sub("feat. ", value or "")


def normalize_remix_group(group):
    open_char = group[0]
    close_char = ")" if open_char == "(" else "]"
    content = normalize_spaces(group[1:-1])
    content = re.sub(r"\brmx\b", "Remix", content, flags=re.IGNORECASE)
    content = re.sub(r"\bremix\b", "Remix", content, flags=re.IGNORECASE)
    content = re.sub(r"\bmix\b", "Mix", content, flags=re.IGNORECASE)
    return f"{open_char}{content}{close_char}"


def pop_remix_groups(value):
    value = normalize_spaces(value)
    groups = []
    while value:
        match = TRAILING_GROUP_RE.match(value)
        if not match:
            break
        group = match.group("group")
        if not REMIX_TOKEN_RE.search(group[1:-1]):
            break
        groups.insert(0, normalize_remix_group(group))
        value = normalize_spaces(match.group("base"))
    return value, groups


def split_feature_suffix(value):
    value = normalize_spaces(normalize_feat_keyword(value))
    patterns = (
        re.compile(r"^(?P<base>.*?)\s*\(\s*(?P<feat>feat\.\s+.+?)\s*\)\s*$", re.IGNORECASE),
        re.compile(r"^(?P<base>.*?)\s*\[\s*(?P<feat>feat\.\s+.+?)\s*\]\s*$", re.IGNORECASE),
        re.compile(r"^(?P<base>.*?)\s+(?P<feat>feat\.\s+.+?)\s*$", re.IGNORECASE),
    )
    for pattern in patterns:
        match = pattern.match(value)
        if match:
            return normalize_spaces(match.group("base")), normalize_spaces(match.group("feat"))
    return value, ""


def feature_names(feat_suffix):
    feat_suffix = normalize_spaces(feat_suffix)
    if not feat_suffix:
        return []
    raw = re.sub(r"^feat\.\s*", "", feat_suffix, flags=re.IGNORECASE)
    return [
        normalize_spaces(part)
        for part in SPLIT_RE.split(raw)
        if normalize_spaces(part)
    ]


def dedupe(values):
    out = []
    seen = set()
    for value in values:
        key = normalize_spaces(value).casefold()
        if key and key not in seen:
            seen.add(key)
            out.append(normalize_spaces(value))
    return out


def build_feat_suffix(names):
    names = dedupe(names)
    if not names:
        return ""
    return "feat. " + ", ".join(names)


def append_feat(artist, feat_suffix):
    artist = normalize_spaces(artist)
    feat_suffix = normalize_spaces(feat_suffix)
    if not feat_suffix:
        return artist
    return normalize_spaces(f"{artist} {feat_suffix}")


def iter_task_items(task):
    if hasattr(task, "items") and task.items:
        return list(task.items)
    if hasattr(task, "item") and task.item:
        return [task.item]
    if hasattr(task, "imported_items"):
        items = task.imported_items()
        if items:
            return list(items)
    return []


def normalize_item(item):
    artist_source = first_non_empty(item.artist, item.albumartist, "Unknown Artist")
    artist_base, artist_feat = split_feature_suffix(artist_source)

    title_source = first_non_empty(item.title, "Unknown Title")
    title_base, remix_groups = pop_remix_groups(title_source)
    title_base, title_feat = split_feature_suffix(title_base)
    title_feat, feat_remix_groups = pop_remix_groups(title_feat)

    names = dedupe(feature_names(artist_feat) + feature_names(title_feat))

    item.artist = append_feat(artist_base, build_feat_suffix(names))
    item.albumartist = first_non_empty(item.albumartist, artist_base)
    item.title = normalize_spaces(" ".join([title_base] + feat_remix_groups + remix_groups))


class DemloCompatPlugin(BeetsPlugin):
    def __init__(self):
        super().__init__()
        self.register_listener("import_task_start", self.import_task_start)

    def import_task_start(self, task, session):
        del session
        for item in iter_task_items(task):
            normalize_item(item)
