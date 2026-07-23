-- Demlo defaults for the local music-tagging workflow.
Color = true
Cores = 0
Exist = 'overwrite'

Extensions = {}
for _, extension in ipairs({'aac', 'ape', 'flac', 'm4a', 'mp3', 'mp4', 'mpc', 'ogg', 'wav', 'wv'}) do
  Extensions[extension] = true
end

Getcover = false
Gettags = false
Prescript = ''
Postscript = ''
Process = false
Scripts = {'10-tag-normalize', '30-tag-case', '60-path', '70-cover'}
