DB_NAME = 'movies-db'
db = undefined
indexedDB = window.webkitIndexedDB

beforeEach ->
  asyncTest ->
    req = indexedDB.open(DB_NAME)
    if not request.ready
      request.onsuccess = ->
        db = request.result
        testDone()

describe 'IDBSchema', ->
  schema = undefined

  beforeEach ->
    schema = IDBSchema.describe(DB_NAME)

  describe '.describe', ->
    it "should initialize a new schema object", ->
      schema = IDBSchema.describe(DB_NAME)
      expect(schema.id).toEqual(DB_NAME)

  describe 'migrate', ->
    it 'creates migrations', ->
      schema.migrate ->
        @
      expect(schema.migrations.length).toEqual(1)
    it 'is chainable', ->
      schema.migrate( ->
        @
      ).migrate( ->
        @
      )
      expect(schema.migrations.length).toEqual(2)

  describe 'createStore', ->
    beforeEach ->
      schema.createStore('movies')

    it 'should create a migration', ->
      expect(schema.migrations.length).toEqual(1)

    it 'should create a store when the migration is run', ->
      asyncTest ->
        idb = IndexedDBBackbone.indexedDB
        idb.deleteDatabase(DB_NAME)
        idb.open(DB_NAME, 1).onupgradeneeded = (e) ->
          # migrations happen
          schema.migrations[0](transaction)

          db.transaction(schema.db).objectStore('movies').get("444-44-4444").onsuccess = function(event) {
            alert("Name for SSN 444-44-4444 is " + event.target.result.name);
          };

        idb.open(DB_NAME, 1).onsuccess = (e) ->
          # expect(db.store('movies').exists())
          testDone()

