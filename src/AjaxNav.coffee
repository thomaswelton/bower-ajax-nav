## Some module
define ['EventEmitter', 'mootools'], (EventEmitter) ->
	class AjaxNav extends EventEmitter
		constructor: () ->
			super()

			## Only ajax nav if we can push state
			return if typeof(history.pushState) isnt 'function'

			@content = document.getElementById 'main'
			@xhr = @getXHR()

			requirejs ['global'], (global) =>
				console.log global

				## Load page specific requireScripts for first load
				requirejs global.requireScripts, (modules...) ->
					for module in modules
						module.load() if module? and typeof module.load is 'function'

				@defaultState = 
					title: document.title
					html: @content.innerHTML
					url: window.location.href
					stylesheets: global.stylesheets
					scripts: global.scripts
					requireScripts: global.requireScripts

				@activeState = @defaultState

				##selector matches internal links
				origin = window.location.origin

				document.body.addEvent "click:relay(a[href^='/'], a[href^='#{origin}'])", @onClick
				window.addEventListener "popstate", @onPop

		getXHR: () =>
			new Request.JSON
				onRequest: () =>
					document.body.style.cursor = "wait"
					
				onSuccess: (json) =>
					document.body.style.cursor = ""

					if json.html?
						@changeState json
						window.history.pushState json, json.title, json.url

		onPop: (event) =>
			@fireEvent 'onPopState'
			@changeState event.state

		onClick: (event) =>
			event.preventDefault()

			if event.target.tagName is 'A'
				href = event.target.href
			else 
				href = event.target.getParent('a').href

			@loadPage href

		unloadRequireScripts: (cb) =>
			## Unload any active scripts that may be running stuff like setIntervals
			requirejs @activeState.requireScripts, (modules...) ->
				for module in modules
					module.unload() if module? and typeof module.unload is 'function'

				cb() if typeof cb is 'function'

		removePageStyles: (state) =>
			if state.stylesheets? then for href in state.stylesheets
				console.log 'removing stylesheet', "link[href*='#{href}']"

				$$("link[href*='#{href}']").destroy()

		loadScripts: (state, cb) =>
			if state.scripts? and state.scripts.length > 0
				requirejs state.scripts, () =>
					cb()
			else
				## No <script> dependencies
				cb()

		loadContent: (state) =>
			## Inject the stylesheets and HTML that may contain <script> dependencies
			## Set the new active state
			if state.stylesheets? then for href in state.stylesheets
				stylesheet = document.createElement 'link'
				stylesheet.setAttribute 'rel', 'stylesheet'
				stylesheet.setAttribute 'type', "text/css"
				stylesheet.setAttribute 'href', href

				head = document.getElementsByTagName('head')[0]
				head.appendChild stylesheet

			@content.set 'html', state.html
			@activeState = state

			## Load require js modules for this page
			requirejs state.requireScripts, (modules...) ->
				for module in modules
					module.load() if module? and typeof module.load is 'function'

			@fireEvent 'onChangeState'

		changeState: (state = @defaultState) =>
			window.scrollTo 0, 0
			document.title = state.title

			## If google analytics is found track ajax load
			if _gaq? then _gaq.push ['_trackPageview', state.url]

			## Unload any active rjs scripts
			@unloadRequireScripts () =>
				## Load all new script dependencies
				## Then loadConetent
				@loadScripts state, () =>
					## Remove stylesheets for the old page
					@removePageStyles @activeState
					@loadContent state

		loadPage: (url) =>
			window.location.reload() if url is window.location.href
			@xhr.cancel() if @xhr.isRunning()

			@xhr.send 
				url: url


	return ajaxNav = new AjaxNav()
