class NanocyteConfigurationSaverMongo
  constructor: ({@datastore}) ->
    throw new Error 'NanocyteConfigurationSaverMongo requires datastore' unless @datastore?

  stop: (options, callback) =>
    {flowId, instanceId} = options
    stopFlowId = "#{flowId}-stop"
    @datastore.findOne {flowId: stopFlowId, instanceId}, (error, record) =>
      return callback error if error?
      @datastore.remove {flowId: stopFlowId, instanceId}, (error) =>
        return callback error if error?
        @datastore.remove {flowId, instanceId}, (error) =>
          return callback error if error?
          record.flowId = flowId
          @datastore.insert record, callback

  save: (options, callback) =>
    {flowId, instanceId, flowData} = options
    flowData = JSON.stringify flowData
    @datastore.insert {flowId, instanceId, flowData}, callback

module.exports = NanocyteConfigurationSaverMongo
