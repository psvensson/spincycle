debug = process.env["DEBUG"]

defer           = require('node-promise').defer
SpinTag         = require('./SpinTag')

class Taginator

  @setTag: (ds, type, id, tag)->
    q = defer()
    Taginator.getTagsFor(ds, type, id).then (existingTags)->
      if existingTags.indexOf(tag) == -1
        record ={name: tag, modelRef: id, modelType: type}
        new SpinTag(record).then (st)->
          st.serialize()
          q.resolve()
      else
        q.resolve()
    return q

  @getTagsFor: (ds, type, id)->
    q = defer()
    ds.findQuery('SpinTag', {property: 'modelType', value: type, property2: 'modelRef', value2: id}).then (results)->
      rv = []
      results.forEach (res) -> rv.push res.name
      q.resolve(rv)
    return q

  @searchForTags: (ds, type, tags) ->
    q = defer()
    lookup = {}
    rv = []
    count = tags.length
    tags.forEach (tag)->
      ds.findQuery('SpinTag', {property: 'modelType', value: type, property2: 'name', value2: tag}).then (results)->
        results.forEach (spintag)->
          found = lookup[spintag.modelRef] or 0
          found++
          lookup[spintag.modelRef] = found
          if --count == 0
            for k,v of lookup
              if v == tags.length then rv.push k
            q.resolve(rv)
    return q

module.exports = Taginator
