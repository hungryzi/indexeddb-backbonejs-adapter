IDBSchema = window.IDBSchema = {
  describe: (id) ->
    return new Schema(id)
}

class Schema
  constructor: (@id) ->
    @migrations = []

  migrate: (migration) ->
    @migrations.push(migration)
    @
  createStore: (name) ->
    createStoreMigration = (transaction) ->
      transaction.createObjectStore(name)
    @migrate(createStoreMigration)
    @
    
