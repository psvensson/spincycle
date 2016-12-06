dogapi = require("dogapi")

"""
options = {
  api_key: "5vvvvvv7adf6cuuuuppp98bc2",
  app_key: "0d2e3ef8tttttaea2efdc5f09",
};
"""

exports.init = (options)->
  dogapi.initialize(options)

region = process.env['REGION']
domain = process.env['DOMAIN']

exports.writePoint = (seriesName, eventData, tags, type = 'gauge') ->
  #console.log 'dogapi writePoint called'
  #console.dir arguments
  #tags.region = region
  #tags.domain = domain
  tagsarray = []
  for k,v of tags
    if not v or v == 'undefined' then v = '_'
    #console.log 'adding tag '+k+' to '+v
    #console.dir v
    tagsarray.push k+':'+ v
  #if eventData == 1 then type = 'count' else type = 'gauge'

  options = {tags: tagsarray, metric_type: type}
  dogapi.metric.send(seriesName,eventData,options,(err,res)->
    if err
      console.log 'ERROR: '+err
    else
      #console.log 'datadog metric result: '
      #console.dir res
  )
