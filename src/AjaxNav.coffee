
requirejs.config
	map:
        '*':
            'css': 'components/require-css/css'

define ['module', 'EventEmitter', 'mootools'], (module, EventEmitter) ->
	class AjaxNav extends EventEmitter
		constructor: (@config) ->
			super()

			roleMain = $$('[role=main]')
			@content = if roleMain.length then roleMain[0] else $ 'main'

			@xhr = @getXHR()
			@head = document.getElementsByTagName('head')[0]

			@defaultState = 
				title: document.title
				html: @content.innerHTML
				url: window.location.href
				stylesheets: @config.stylesheets
				scripts: @config.scripts
				requireScripts: @config.requireScripts

			@activeState = @defaultState

			requirejs @config.requireScripts, (modules...) =>
				for module in modules
					module.load() if module? and typeof module.load is 'function'

				## Only ajax nav if we can push state
				return if typeof(history.pushState) isnt 'function'

				##selector matches internal links
				origin = window.location.origin
				
				$(document.body).addEvent "click:relay(a[href^='/']:not([data-ajax-nav=false], [target=_blank]), a[href^='#{origin}']:not([data-ajax-nav=false], [target=_blank]))", @onEvent
				$(document.body).addEvent "submit:relay(form[action^='/']:not([data-ajax-nav=false], [target=_blank]), form[action^='#{origin}']:not([data-ajax-nav=false], [target=_blank]))", @onEvent
				window.addEventListener "popstate", @onPop

		getXHR: () =>
			xhr = new Request
				onRequest: () =>
					@fireEvent 'onRequest'
					document.body.style.cursor = "wait"
					
				onSuccess: (responseText) =>
					if refresh = xhr.getHeader 'Refresh'
						console.log refresh
						# Code igniter refresh redirect responds with
						# "0;url=http://site.com/someurl"
						
						url = refresh.split('=')[1]
						return window.location = url

					@fireEvent 'onXHRSuccess', responseText
					document.body.style.cursor = ""

					json = JSON.decode responseText
					if json.html?
						@changeState json
						window.history.pushState json, json.title, json.url

				onFailure: (response) =>
					document.documentElement.innerHTML = response.response

		onPop: (event) =>
			@fireEvent 'onPopState', event
			@changeState event.state

		onEvent: (event) =>
			## Exclude clicks that open in a new window, tab, trigger a download or whose default action was prevented
			return if event.shift or event.alt or event.meta or event.event.defaultPrevented
			event.preventDefault()

			console.log event

			switch event.type
				when 'click' then @onClick event
				when 'submit' then @onSubmit event

		onClick: (event) =>
			if event.target.tagName is 'A'
				link = event.target
			else 
				link = event.target.getParent('a')

			href = link.href
			@loadPage href

		onSubmit: (event) =>
			if event.target.tagName is 'FORM'
				form = event.target
			else 
				form = event.target.getParent('form')

			@submitForm form

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
			return if $$("link[href*='#{href}']").length > 0
			
			stylesheet = document.createElement 'link'
			stylesheet.setAttribute 'rel', 'stylesheet'
			stylesheet.setAttribute 'type', "text/css"
			stylesheet.setAttribute 'href', href

			@head.appendChild stylesheet

		loadContent: (state) =>
			## Set the new active state
			## Load CSS for this content using require-css plugin
			loadStyles = []
			if state.stylesheets?
				loadStyles.push "css!#{href}" for href in state.stylesheets

			requirejs loadStyles, () =>
				if state.stylesheets?
					for href in state.stylesheets
						## Bugfix workaround. These should have been injected by
						## require-css but after deleted require-css wont add them again 
						@injectStylesheet href
						console.log "Loaded stylesheet #{href}" 

				## Inject the HTML that may contain <script> dependencies
				@content.set 'html', state.html
				@activeState = state

				## Load require js modules for this page
				requirejs state.requireScripts, (modules...) ->
					for module in modules
						module.load() if module? and typeof module.load is 'function'

				@fireEvent 'onContentLoaded', state

		changeState: (state = @defaultState) =>
			return if state is @activeState

			window.scrollTo 0, 0
			document.title = state.title

			## Unload any active rjs scripts
			@unloadRequireScripts () =>
				## Load all new script dependencies
				## Then loadConetent
				@loadScripts state, () =>
					## Remove stylesheets for the old page
					@removePageStyles @activeState
					@loadContent state

		submitForm: (form) =>
			return if @xhr.isRunning()
			
			@xhr.send
				url: form.getProperty 'action'
				data: form

		loadPage: (url) =>
			window.location.reload() if url is window.location.href
			@xhr.cancel() if @xhr.isRunning()

			@xhr.send 
				url: url
				method: 'get'


	return ajaxNav = new AjaxNav(module.config())
