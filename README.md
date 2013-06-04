bower-ajax-nav
==============
[![Build Status](https://travis-ci.org/thomaswelton/bower-ajax-nav.png)](https://travis-ci.org/thomaswelton/bower-ajax-nav)
[![Dependency Status](https://david-dm.org/thomaswelton/bower-ajax-nav.png)](https://david-dm.org/thomaswelton/bower-ajax-nav)


Ajax Navigation component

This module uses `require-css` to load CSS files. This needs to be added to your requirejs config

```coffee
requirejs.config
	map:
	    '*':
	        'css': 'path/to/require-css/css'
```


Add data attribute `data-ajax-nav="false"` to links or forms to disable ajax loading

### Events

onContentLoaded - Fire when the html is updates returns state
onPopState - Fired on popstate returns event
onRequest - On XHR request
onXHRSuccess - On XHR success returns XHR response text