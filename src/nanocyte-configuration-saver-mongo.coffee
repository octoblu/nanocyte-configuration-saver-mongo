async = require 'async'
crypto = require 'crypto'

class NanocyteConfigurationSaverMongo
  constructor: ({@datastore}) ->
    throw new Error 'NanocyteConfigurationSaverMongo requires datastore' unless @datastore?

  stop: (options, callback) =>
    {flowId, instanceId} = options
    stopFlowId = "#{flowId}-stop"
    @datastore.find {flowId: stopFlowId}, (error, records) =>
      return callback error if error?
      async.each records, async.apply(@_replaceConfig, flowId), callback

  _replaceConfig: (flowId, record, callback) =>
    {instanceId, flowData, hash} = record
    stopFlowId = record.flowId
    # remove old config
    @datastore.remove {flowId, instanceId}, (error) =>
      return callback error if error?
      # replace it with stop config
      @datastore.insert {flowId, instanceId, flowData, hash}, (error) =>
        return callback error if error?
        # remove stop config
        @datastore.remove {flowId: stopFlowId, instanceId}, callback

  save: (options, callback) =>
    {flowId, instanceId, flowData} = options
    flowData = JSON.stringify flowData
    hash = @hash flowData
    @datastore.insert {flowId, instanceId, flowData, hash}, callback

  hash: (flowData) =>
    crypto.createHash('sha256').update(flowData).digest 'hex'

module.exports = NanocyteConfigurationSaverMongo
