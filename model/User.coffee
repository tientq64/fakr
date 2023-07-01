class User extends Phaser.GameObjects.Container

	constructor: (data, isMe) ->
		super game, data.x * app.px, data.y * app.px
		@ctor = @constructor
		@data = data
		@state = "idle"
		@isMe = isMe
		@w = 1
		@h = 1
		@stepX = 0
		@stepY = 0
		@skin = null
		@coat = null
		@face = null
		@hair = null
		@isStandOnce = undefined
		@initForms()
		@setForm "skin"
		@setForm "coat"
		@setForm "face"
		@setForm "hair"
		@setD()
		@addToUsers() unless isMe

	updateDb: (data) ->
		meDb.update data if @isMe
		return

	addToUsers: ->
		game.add.existing @
		app.users.add @
		return

	initForms: ->
		for key of @ctor.forms
			spr = game.make.sprite {key}
			spr.setOrigin .25, .5
			@[key] = spr
			@add spr
		return

	setD: (d = @data.d) ->
		@data.d = d
		for key of @ctor.forms
			@setFormFrame key, 1
		[@stepX, @stepY] = [[0, 1], [-1, 0], [0, -1], [1, 0]][d]
		@updateDb {d}
		return

	setFormFrame: (key, added = 0) ->
		form = @ctor.forms[key]
		@[key].setFrame @data[key] // form.col * form.col * 12 +
			@data.d * form.col * 3 + @data[key] % form.col * 3 + added
		return

	setForm: (key, val = @data[key]) ->
		@data[key] = val
		@[key].setTexture key
		@setFormFrame key, 1
		@updateDb [key]: val
		return

	getFrontXY: (dist = 1) ->
		x: @data.x + @stepX * dist
		y: @data.y + @stepY * dist

	getFrontTile: (dist = 1) ->
		{x, y} = @getFrontXY dist
		app.floor.getTileAt(x, y) or app.wall.getTileAt(x, y)

	checkCollide: ->
		{x, y} = @getFrontXY 1
		{width, height} = app.map
		0 <= x <= width - @w and
		(@data.map[0] is "h" and 2 or 0) <= y <= height - @h and
		not app.wall.getTileAt x, y

	action: ->
		if tile = @getFrontTile 1
		else if tile = @getFrontTile 2
			switch tile.index
				when 88
					dat = new Date
					app.addMessage "
						Bây giờ là
						#{(dat.getHours()+"").padStart 2, 0}:
						#{(dat.getMinutes()+"").padStart 2, 0}.
					"
		return

	stand: ->
		if @isMe
			if tile = @getFrontTile 0
				switch tile.index
					when 113
						444
		return

	stepMove: ->
		if @checkCollide()
			{x, y} = @getFrontXY 1
			@state = "move"
			@data.x = x
			@data.y = y
			for key of @ctor.forms
				@[key].anims.play "#{key}-#{@data[key]}-#{@data.d}"
			@updateDb {x, y}
		return

	stopMove: ->
		@state = "idle"
		for key of @ctor.forms
			@[key].anims.stop()
			@setFormFrame key, 1
		@stand()
		return

	update: ->
		if @state is "move"
			{x, y} = @data
			x *= app.px
			y *= app.px
			if @x < x then @x++
			else if @x > x then @x--
			if @y < y then @y++
			else if @y > y then @y--
			if @x is x and @y is y
				@stopMove()
		return

	@forms =
		skin: len: 1, col: 1
		coat: len: 176, col: 50
		face: len: 29, col: 29
		hair: len: 247, col: 50
