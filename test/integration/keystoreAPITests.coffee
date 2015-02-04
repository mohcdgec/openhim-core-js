should = require "should"
request = require "supertest"
testUtils = require "../testUtils"
auth = require("../testUtils").auth
server = require "../../lib/server"
Keystore = require('../../lib/model/keystore').Keystore
Certificate = require('../../lib/model/keystore').Certificate
sinon = require "sinon"

describe 'API Integration Tests', ->

  describe "Keystore API Tests", ->

    authDetails = {}

    before (done) ->
      auth.setupTestUsers (err) ->
        server.start null, null, 8080, null, null, false,  ->
          done()

    after (done) ->
      auth.cleanupTestUsers (err) ->
        server.stop ->
          done()

    beforeEach ->
      authDetails = auth.getAuthDetails()

    afterEach (done) ->
      Keystore.remove {}, ->
        done()

    setupTestData = (callback) ->
      cert1 = new Certificate
        country: 'ZA'
        state: 'KZN'
        locality: 'Berea'
        organization: 'Jembi Health Systems NPC'
        organizationUnit: 'HISD'
        commonName: 'client1.openhim.org'
        emailAddress: 'client1@openhim.org'
        validity:
          start: new Date 2010, 0, 0
          end: new Date 2050, 0, 0

      cert2 = new Certificate
        country: 'ZA'
        state: 'WC'
        locality: 'Westlake'
        organization: 'Jembi Health Systems NPC'
        organizationUnit: 'HISD'
        commonName: 'client2.openhim.org'
        emailAddress: 'client2@openhim.org'
        validity:
          start: new Date 2010, 0, 0
          end: new Date 2050, 0, 0

      keystore = new Keystore
        key: 'key test value'
        cert: 'cert test value'
        ca: [ cert1, cert2 ]

      keystore.save -> callback()

    it "Should fetch the current HIM server certificate", (done) ->
      setupTestData ->
        request("https://localhost:8080")
          .get("/keystore/cert")
          .set("auth-username", testUtils.rootUser.email)
          .set("auth-ts", authDetails.authTS)
          .set("auth-salt", authDetails.authSalt)
          .set("auth-token", authDetails.authToken)
          .expect(200)
          .end (err, res) ->
            if err
              done err
            else
              res.body.cert.should.be.exactly 'cert test value'
              done()

    it "Should not allow a non-admin user to fetch the current HIM server certificate", (done) ->
      setupTestData ->
        request("https://localhost:8080")
          .get("/keystore/cert")
          .set("auth-username", testUtils.nonRootUser.email)
          .set("auth-ts", authDetails.authTS)
          .set("auth-salt", authDetails.authSalt)
          .set("auth-token", authDetails.authToken)
          .expect(403)
          .end (err, res) ->
            if err
              done err
            else
              done()
