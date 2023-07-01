app = new Vue
	el: "#app"

	data: ->
		state: "load"
		game: null
		px: 16
		me: null
		users: null
		map: null
		bg: null
		floor: null
		wall: null
		ceil: null
		key: undefined
		isJustDownKey: undefined
		message:
			list: []
			words: []
			isCanNext: yes
		dialogs: []
		tips: [
			"Sử dụng các phím W, A, S, D để di chuyển"
		]
		config:
			keys:
				KeyW:
					code: "KeyW"
					label: "Di chuyển lên"
				KeyA:
					code: "KeyA"
					label: "Di chuyển trái"
				KeyS:
					code: "KeyS"
					label: "Di chuyển xuống"
				KeyD:
					code: "KeyD"
					label: "Di chuyển phải"
				KeyE:
					code: "KeyE"
					label: "Hành động"

	computed:
		styleDom: ->
			{x, y, width, height} = game.scale.canvasBounds
			left: x + "px"
			top: y + "px"
			width: width + "px"
			height: height + "px"

		randomTips: ->
			Phaser.Math.RND.pick @tips

	watch:
		config:
			handler: (val) ->
				localStorage.config = JSON.stringify val
				return
			deep: yes

	methods:
		loadConfig: ->
			try Object.assign @config, JSON.parse localStorage.config
			return

		addMessage: (text, title) ->
			new Promise (resolve) =>
				allWords = text.split " "
				words = []
				list = []
				index = 0
				el = @$refs.measureText
				for word, i in allWords
					words.push word
					el.textContent = words.join " "
					isNext = el.offsetHeight > 48
					isLast = i is allWords.length-1
					if isNext or isLast
						index++
						message = {words, title, index}
						list.push message
						@message.list.push message
						if isNext
							words = [words.pop()]
						if isLast
							@message.resolve = resolve
							message.total = index for message from list
				return

		nextMessage: ->
			@message.words = []
			@message.list.shift()
			return

		alert: (text) ->
			new Promise (resolve) =>
				dialog =
					type: "alert"
					text: text
					resolve: =>
						resolve yes
						@removeDialog dialog
						return
				@dialogs.push dialog
				return

		confirm: (text) ->
			new Promise (resolve) =>
				dialog =
					type: "confirm"
					text: text
					resolve: (event) =>
						resolve !!event
						@removeDialog dialog
						return
				@dialogs.push dialog
				return

		prompt: (text, input = {}) ->
			new Promise (resolve) =>
				input = value: input unless typeof input is "object"
				input.value ?= ""
				dialog =
					type: "prompt"
					text: text
					input: input
					resolve: (event) =>
						if event
							if event.target.reportValidity()
								prop = dialog.type is "number" and "valueAsNumber" or "value"
								resolve event.target.elements[0][prop]
								@removeDialog dialog
						else
							resolve null
							@removeDialog dialog
						return
				@dialogs.push dialog
				return

		removeDialog: (dialog) ->
			@dialogs.splice @dialogs.indexOf(dialog), 1
			return

		showDialog: (id) ->
			document.getElementById(id).show()
			return

		closeDialog: (event) ->
			event.target.closest("dialog").close()
			return

		loginWithGoogle: ->
			provider = new firebase.auth.GoogleAuthProvider
			await auth.signInWithRedirect provider
			return

		initAnims: ->
			for key, form of User.forms
				for d in [0..3]
					for index in [0..form.len]
						frame = index // form.col * form.col * 12 +
							d * form.col * 3 + index % form.col * 3
						game.anims.create
							key: "#{key}-#{index}-#{d}"
							frames: game.anims.generateFrameNumbers key,
								start: frame
								end: frame + 2
							frameRate: 12
							repeat: -1
							yoyo: yes
			return

		initEvents: ->
			game.input.keyboard.on "keydown", (event) =>
				if @state is "play"
					@isJustDownKey ?= yes
					@key = event.code
				return
			game.input.keyboard.on "keyup", (event) =>
				@key = @isJustDownKey = undefined
				return
			return

		loadMap: ->
			new Promise (resolve) =>
				@state = "load"
				game.load.tilemapTiledJSON "tilemap", "map/#{@me.data.map}.json"
				game.load.once "complete", =>
					if @map
						@map.destroy()
						@bg.destroy()
						@floor.destroy()
						@wall.destroy()
						@users.destroy()
						@ceil.destroy()
					@map = game.add.tilemap "tilemap"
					@map.addTilesetImage "map"
					@bg = @map.createStaticLayer "bg", "map"
					@floor = @map.createStaticLayer "floor", "map"
					@wall = @map.createStaticLayer "wall", "map"
					@users = game.add.group()
					@me.addToUsers()
					@ceil = @map.createStaticLayer "ceil", "map"
					@state = "play"
					resolve()
					return
				game.load.start()
				return

		preload: ->
			game = @game = game.scene.scenes[0]
			game.scale.lockOrientation "landscape"
			game.cameras.main.setZoom 4
			game.load.image "map", "map/map.png"
			game.load.spritesheet "skin", "user/skin.png", frameWidth: 32
			game.load.spritesheet "coat", "user/coat.png", frameWidth: 32
			game.load.spritesheet "face", "user/face.png", frameWidth: 32
			game.load.spritesheet "hair", "user/hair.png", frameWidth: 32
			return

		create: ->
			auth.onAuthStateChanged (user) =>
				if user
					usersDb = db.ref "users"
					meDb = usersDb.child user.uid
					meDb.once "value", (snap) =>
						if snap.exists()
							meData = snap.val()
						else
							meData =
								x: 6
								y: 4
								d: 1
								name: ""
								skin: 0
								coat: 44
								face: 12
								hair: 192
								map: "h1"
								online: yes
							meData.name = await app.prompt "Nhập tên nhân vật",
								pattern: "^[a-z0-9]+$"
								minlength: 6
								maxlength: 12
								required: yes
							await meDb.update meData
						@me = new User meData, yes
						game.cameras.main.startFollow @me, no, 1, 1, -@px / 2, -@px * .75
						@initAnims()
						@initEvents()
						await @loadMap()
						return
				else
					game.scene.restart() if @state is "play"
					@state = "login"
				return
			return

		update: ->
			if @state is "play"
				if @me.state is "idle"
					switch @key
						when @config.keys.KeyW.code
							@me.setD 2
							@me.stepMove()
						when @config.keys.KeyA.code
							@me.setD 1
							@me.stepMove()
						when @config.keys.KeyS.code
							@me.setD 0
							@me.stepMove()
						when @config.keys.KeyD.code
							@me.setD 3
							@me.stepMove()
						when @config.keys.KeyE.code
							if @isJustDownKey
								if @message.list[0]
									if @message.isCanNext
										@nextMessage()
								else
									@me.action()
				@users.children.each (user) =>
					user.update()
					return
				if message = @message.list[0]
					if word = message.words.shift()
						@message.words.push word
					@message.isCanNext = not word
				n++
			@isJustDownKey = no if @isJustDownKey
			return

	mounted: ->
		@loadConfig()
		game = new Phaser.Game
			width: innerWidth
			height: innerHeight
			type: Phaser.WEBGL
			canvas: @$refs.canvas
			disableContextMenu: yes
			loader:
				path: "asset/"
			scale:
				mode: Phaser.Scale.FIT
				autoCenter: Phaser.Scale.CENTER_BOTH
			render:
				pixelArt: yes
			dom:
				createContainer: yes
			title: "Fakr"
			version: "0.1"
			scene: {@preload, @create, @update}
		return
