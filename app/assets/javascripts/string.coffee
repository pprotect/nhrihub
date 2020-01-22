String::capitalize = -> @charAt(0).toUpperCase() + @slice(1)
String::singularize = -> @replace(/s$/,'')
String::downcase = -> @charAt(0).toLowerCase() + @slice(1)
String::underscore = -> @replace(/\s/g,'_').toLowerCase()
String::titlecase = -> @replace(/(?:^|\s)\w/g,(match) -> match.toUpperCase())
String::humanize = -> @replace(/_/,' ')
