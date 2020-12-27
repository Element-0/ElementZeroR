import xmlparser
from parsexml import allowEmptyAttribs

proc loadModRepos*(path: string) =
  let xml = loadXml(path, { allowEmptyAttribs })