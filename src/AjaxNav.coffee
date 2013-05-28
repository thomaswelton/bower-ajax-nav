## Some module
define ['EventEmitter', 'mootools'], (EventEmitter) ->
	class AjaxNav extends EventEmitter
		constructor: () ->
			super()

			## Only ajax nav if we can push state
			return if typeof(history.pushState) isnt 'function'

			@content = document.getElementById 'main'
			@xhr = @getXHR()
			@head = document.getElementsByTagName('head')[0]

			requirejs ['global'], (global) =>
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

				_this = @
				
				window.addEventListener "popstate", @onPop

				document.body.addEvent "click:relay(a[href^='/'], a[href^='#{origin}'])", (event) ->
					## Exclude clicks that open in a new window, tab or trigger a download
					return if event.shift or event.alt or event.meta
					
					event.preventDefault()
					_this.loadPage this.href

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

		unloadRequireScripts: (cb) =>
			## Unload any active scripts that may be running stuff like setIntervals
			
			onUnloadSuccess = (modules...) ->
				for module in modules
					module.unload() if module? and typeof module.unload is 'function'

			onUnloadError = (error) ->
				console.error 'AjaxNav: RequireJS unloadRequireScripts', error

			console.log 'unload', @activeState.requireScripts
			requirejs @activeState.requireScripts, onUnloadSuccess, onUnloadError

			cb() if typeof cb is 'function'

		removePageStyles: (state) =>
			if state.stylesheets? then for href in state.stylesheets
				console.log 'removing stylesheet', "link[href*='#{href}']"

				$$("link[href*='#{href}']").destroy()

		loadScripts: (state, cb) =>
			## Load in <script> files before injecting HTML
			if state.scripts? and state.scripts.length > 0
				
				## On Success callback
				loadScriptsSuccess = cb

				## On error log message and force normal page load
				loadScriptsError = (error) ->
					console.warn "AjaxNav loadScripts: RequireJS failed to load scripts due to #{error.requireType}", error.requireModules
					## Even if the scrips fail to load the page should continue trying to load
					loadScriptsSuccess()

				requirejs state.scripts, loadScriptsSuccess, loadScriptsError
			else
				## No <script> dependencies
				cb()

		injectStylesheet: (href) =>
			stylesheet = document.createElement 'link'
			stylesheet.setAttribute 'rel', 'stylesheet'
			stylesheet.setAttribute 'type', "text/css"
			stylesheet.setAttribute 'href', href

			@head.appendChild stylesheet

		loadContent: (state) =>
			## Inject the stylesheets and HTML that may contain <script> dependencies
			## Set the new active state
			if state.stylesheets? then @injectStylesheet href for href in state.stylesheets

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
				method: 'get'


	return ajaxNav = new AjaxNav()
