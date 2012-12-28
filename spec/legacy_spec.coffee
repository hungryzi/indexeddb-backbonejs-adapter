describe "indexdb backbone driver", ->
  it "creates model v1", ->
    asyncTest ->
      movie = new Moviev1()
      movie.save
         title: "The Matrix",
         format: "dvd"
      ,
         success: testDone
         error: (o, error) -> fail(error.toString())

  it "doesn't create duplicate models", ->
    asyncTest ->
      movie = new Movie()
      movie.save
        title: "The Matrix",
        format: "dvd"
      ,
        success: () ->
          duplicatedRecord = new Movie()
          duplicatedRecord.isNew = () ->
            true # BAckbone uses isNew to detecth whether to do an update or a create, and isNew is by default based on the presence of an "id" attribute.
          duplicatedRecord.save
            id: movie.id,
            title: "The Matrix, the movie",
            format: "streaming"
          ,
            success: -> fail("The duplicate should been refused")
            error: testDone

        error: (o, error) -> fail(error.toString())

  it "create model v2", ->
    asyncTest ->
      movie = new Movie()
      movie.save
        title: "The Matrix"
        format: "dvd"
      ,
        success: testDone
        error: (o, error) -> fail(error.toString())

  it "read model with id", ->
    asyncTest ->
      movie = new Movie()
      movie.save
        title: "Avatar"
        format: "blue-ray"
      ,
        success: ->
          saved = new Movie(id: movie.id)
          saved.fetch
            success: (object) ->
              expect(saved.toJSON().title).toEqual("Avatar")
              expect(saved.toJSON().format).toEqual("blue-ray")
              expect(object.toJSON().title).toEqual("Avatar")
              expect(object.toJSON().format).toEqual("blue-ray")
              testDone()

            error: (object, error) -> fail(error.toString())

        error: (object, error) -> fail(error.toString())

  it "read model with index", ->
    asyncTest ->
      saveMovieAndReadWithIndex = (movie) ->
        movie.save {},
          success: ->
            movie2 = new Movie(title: "Avatar")
            movie2.fetch
              success: (object) ->
                expect(movie2.toJSON().title).toEqual(movie.toJSON().title)
                expect(movie2.toJSON().format).toEqual(movie.toJSON().format)
                testDone()

              error: (object, error) -> fail(error.toString())

          error: (object, error) -> fail(error.toString())

      movie = new Movie(title: "Avatar")
      movie.fetch
        success: ->
          movie.destroy success: ->
            saveMovieAndReadWithIndex movie

        error: ->
          saveMovieAndReadWithIndex movie

  it "read model that do not exist with index", ->
    asyncTest ->
      movie = new Movie(title: "Memento")
      movie.fetch
        success: (object) ->
          fail("Model should not exist: #{object}")

        error: (object, error) ->
          expect(error.toString()).toEqual('Not Found')
          testDone()

  it "updates model", ->
    asyncTest ->
      movie = new Movie()
      movie.save
        title: "Star Wars, Episode IV"
        format: "dvd"
      ,
        success: ->
          movie.save
            title: "Star Wars, Episode V"
          ,
            success: ->
              movie.fetch
                success: (object) ->
                  expect(movie.toJSON().title).toEqual("Star Wars, Episode V")
                  expect(movie.toJSON().format).toEqual("dvd")
                  testDone()

                error: (object, error) -> fail(error.toString())

            error: (object, error) -> fail(error.toString())

        error: (object, error) -> fail(error.toString())

  it "delete model", ->
    asyncTest ->
      movie = new Movie()
      movie.save
        title: "Avatar"
        format: "blue-ray"
      ,
        success: (object) ->

          # success
          movie.destroy
            success: (object) ->
              movie.fetch
                success: (object) ->
                  fail("should not exist: #{object}")

                error: (object, error) ->
                  expect(error).toEqual("Not Found")
                  testDone()

            error: (object, error) -> fail(error.toString())

        error: (object, error) -> fail(error.toString())
          # expect(false).toEqual(true)

  describe "reads collection", ->
    theater = null

    beforeEach ->
      theater = new Theater()

    runReadCollectionTest = (test) ->
      asyncTest ->
        theater.fetch
          success: ->
            deleteNext theater.models, ->
              addAllMovies null, test

    it "with no options", ->
      runReadCollectionTest ->
        theater.fetch
          success: ->
            expect(theater.models.length).toEqual(5)
            expect(theater.pluck("title")).toEqual(["Hello", "Bonjour", "Halo", "Nihao", "Ciao"])
            testDone()

    it "with limit", ->
      runReadCollectionTest ->
        theater.fetch
          limit: 3
          success: ->
            expect(3).toEqual(theater.models.length)
            expect(theater.pluck("title")).toEqual(["Hello", "Bonjour", "Halo"])
            testDone()

    it "with offset", ->
      runReadCollectionTest ->
        theater.fetch
          offset: 2
          success: ->
            expect(theater.models.length).toEqual(3)
            expect(theater.pluck("title")).toEqual(["Halo", "Nihao", "Ciao"])
            testDone()

    it "with offset and limit", ->
      runReadCollectionTest ->
        theater.fetch
          offset: 1
          limit: 2
          success: ->
            expect(theater.models.length).toEqual(2)
            expect(theater.pluck("title")).toEqual(["Bonjour", "Halo"])
            testDone()

    it "with range", ->
      runReadCollectionTest ->
        theater.fetch
          range: ["1.5", "4.5"]
          success: ->
            expect(theater.models.length).toEqual(3)
            expect(theater.pluck("title")).toEqual(["Bonjour", "Halo", "Nihao"])
            testDone()

    it "via condition on index with a single value", ->
      runReadCollectionTest ->
        theater.fetch
          conditions:
            format: "dvd"
          success: ->
            expect(theater.models.length).toEqual(2)
            expect(theater.pluck("title")).toEqual(["Bonjour", "Ciao"])
            testDone()

    it "read collection via condition on index with a range", ->
      runReadCollectionTest ->
        theater.fetch
          conditions:
            format: ["a", "f"]
          success: ->
            expect(theater.models.length).toEqual(4)
            expect(theater.pluck("title")).toEqual(["Hello", "Halo", "Bonjour", "Ciao"])
            testDone()

    it "via condition on index with a range and a limit", ->
      runReadCollectionTest ->
        theater.fetch
          limit: 2
          conditions:
            format: ["a", "f"]
          success: ->
            expect(theater.models.length).toEqual(2)
            expect(theater.pluck("title")).toEqual(["Hello", "Halo"])
            testDone()

    it "via condition on index with a range, an offset and a limit", ->
      runReadCollectionTest ->
        theater.fetch
          offset: 2
          limit: 2
          conditions:
            format: ["a", "f"]
          success: ->
            expect(theater.models.length).toEqual(2)
            expect(theater.pluck("title")).toEqual(["Bonjour", "Ciao"])
            testDone()

    it "via condition on index with a range reversed", ->
      runReadCollectionTest ->
        theater.fetch
          conditions:
            format: ["f", "a"]
          success: ->
            expect(theater.models.length).toEqual(4)
            expect(theater.pluck("title")).toEqual(["Ciao", "Bonjour", "Halo", "Hello"])
            testDone()

    xit "support for the 'addIndividually' property", ->
      runReadCollectionTest ->
        spy = jasmine.createSpy 'add'

        theater = new Theater()
        theater.on "add", spy
        theater.fetch
          addIndividually: true
          success: ->
            expect(spy.callCount).toEqual 5
            testDone()
          error: ->
            fail()

  it "support for model specific sync override", ->
    expect(typeof Backbone.ajaxSync).toEqual("function")

  it "model add with keyPath specified", ->
    asyncTest ->
      torrent = new Torrent()
      torrent.save
        id: 1
        title: "The Matrix"
        format: "dvd"
      ,
        success: testDone
        error: (o, error) -> fail(error.toString())

  it "model update with keyPath specified", ->
    asyncTest ->
      torrent = new Torrent()
      torrent.save
        id: 1
        title: "The Matrix"
        format: "dvd"
      ,
        error: (o, error) -> fail(error.toString())
        success: ->
          torrent = new Torrent(id: 1)
          torrent.fetch
            success: ->
              expect(torrent.get("title")).toEqual("The Matrix")
              torrent.save
                rating: 5
              ,
                success: testDone
                error: (o, error) -> fail(error.toString())

            error: (o, error) -> fail(error.toString())
