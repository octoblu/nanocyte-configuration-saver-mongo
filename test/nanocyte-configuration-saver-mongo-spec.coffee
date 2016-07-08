_                      = require 'lodash'
Datastore              = require 'meshblu-core-datastore'
mongojs                = require 'mongojs'
ConfigrationSaverMongo = require '..'

describe 'ConfigrationSaverMongo', ->
  beforeEach (done) ->
    db = mongojs 'localhost/flow-config-test', ['instances']
    @datastore = new Datastore
      database: db
      collection: 'instances'
    db.instances.remove done

  beforeEach ->
    @sut = new ConfigrationSaverMongo {@datastore}

  describe '->save', ->
    beforeEach (done) ->
      @flowData =
        router:
          config: {}
          data: {}

      @sut.save flowId: 'some-flow-uuid', instanceId: 'my-instance-id', flowData: @flowData, done

    it 'should save to mongo', (done) ->
      @datastore.findOne {flowId: 'some-flow-uuid', instanceId: 'my-instance-id'}, (error, {flowData, hash}) =>
        return done error if error?
        expect(JSON.parse flowData).to.deep.equal @flowData
        expect(hash).to.equal 'b9a0d397b7ed55c26440b0281328735e06e961bda05869de6f4718f7fea8a8cb'
        done()

  describe '->stop', ->
    describe 'with one instance', ->
      beforeEach (done) ->
        @flowData =
          router:
            config: {}
            data: {}

        @sut.save flowId: 'some-flow-uuid', instanceId: 'my-instance-id', flowData: @flowData, done

      beforeEach (done) ->
        @flowData = 'stop'

        @sut.save flowId: 'some-flow-uuid-stop', instanceId: 'my-instance-id', flowData: @flowData, done

      beforeEach (done) ->
        @sut.stop flowId: 'some-flow-uuid', instanceId: 'my-instance-id', done

      it 'should remove the stop configuration', (done) ->
        @datastore.findOne {flowId: 'some-flow-uuid-stop', instanceId: 'my-instance-id'}, (error, result) =>
          return done error if error?
          expect(result).not.to.exist
          done()

      describe 'after the config is removed', ->
        it 'should replace the configuration with the stop configuration', (done) ->
          @datastore.findOne {flowId: 'some-flow-uuid', instanceId: 'my-instance-id'}, (error, {flowData}) =>
            return done error if error?
            expect(JSON.parse flowData).to.equal 'stop'
            done()

    describe 'with two instances', ->
      beforeEach (done) ->
        @flowData =
          router:
            config: {}
            data: {}

        @sut.save flowId: 'some-flow-uuid', instanceId: 'my-instance-id', flowData: @flowData, done

      beforeEach (done) ->
        @flowData = 'other instance'

        @sut.save flowId: 'some-flow-uuid', instanceId: 'other-instance-id', flowData: @flowData, done

      beforeEach (done) ->
        @flowData = 'stop'

        @sut.save flowId: 'some-flow-uuid-stop', instanceId: 'my-instance-id', flowData: @flowData, done

      beforeEach (done) ->
        @flowData = 'stop'

        @sut.save flowId: 'some-flow-uuid-stop', instanceId: 'other-instance-id', flowData: @flowData, done

      beforeEach (done) ->
        @sut.stop flowId: 'some-flow-uuid', instanceId: 'my-instance-id', done

      it 'should remove the stop configuration', (done) ->
        @datastore.findOne {flowId: 'some-flow-uuid-stop', instanceId: 'my-instance-id'}, (error, result) =>
          return done error if error?
          expect(result).not.to.exist
          done()

      describe 'after the config is removed', ->
        it 'should replace the configuration with the stop configuration', (done) ->
          @datastore.findOne {flowId: 'some-flow-uuid', instanceId: 'my-instance-id'}, (error, {flowData}) =>
            return done error if error?
            expect(JSON.parse flowData).to.equal 'stop'
            done()

        it 'should change the other instance', (done) ->
          @datastore.findOne {flowId: 'some-flow-uuid', instanceId: 'other-instance-id'}, (error, {flowData}) =>
            return done error if error?
            expect(JSON.parse flowData).to.equal 'stop'
            done()
