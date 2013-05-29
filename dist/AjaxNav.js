(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    __slice = [].slice;

  define(['EventEmitter', 'mootools'], function(EventEmitter) {
    var AjaxNav, ajaxNav;

    AjaxNav = (function(_super) {
      __extends(AjaxNav, _super);

      function AjaxNav() {
        this.loadPage = __bind(this.loadPage, this);
        this.changeState = __bind(this.changeState, this);
        this.loadContent = __bind(this.loadContent, this);
        this.injectStylesheet = __bind(this.injectStylesheet, this);
        this.loadScripts = __bind(this.loadScripts, this);
        this.removePageStyles = __bind(this.removePageStyles, this);
        this.unloadRequireScripts = __bind(this.unloadRequireScripts, this);
        this.onSubmit = __bind(this.onSubmit, this);
        this.onClick = __bind(this.onClick, this);
        this.onEvent = __bind(this.onEvent, this);
        this.onPop = __bind(this.onPop, this);
        this.getXHR = __bind(this.getXHR, this);
        var _this = this;

        AjaxNav.__super__.constructor.call(this);
        if (typeof history.pushState !== 'function') {
          return;
        }
        this.content = document.getElementById('main');
        this.xhr = this.getXHR();
        this.head = document.getElementsByTagName('head')[0];
        requirejs(['global'], function(global) {
          var origin;

          _this.defaultState = {
            title: document.title,
            html: _this.content.innerHTML,
            url: window.location.href,
            stylesheets: global.stylesheets,
            scripts: global.scripts,
            requireScripts: global.requireScripts
          };
          _this.activeState = _this.defaultState;
          origin = window.location.origin;
          document.body.addEvent("click:relay(a[href^='/']:not([data-ajax-nav=false]), a[href^='" + origin + "']:not([data-ajax-nav=false]))", _this.onEvent);
          document.body.addEvent("submit:relay(form[action^='/']:not([data-ajax-nav=false]), form[action^='" + origin + "']:not([data-ajax-nav=false]))", _this.onEvent);
          return window.addEventListener("popstate", _this.onPop);
        });
      }

      AjaxNav.prototype.getXHR = function() {
        var xhr,
          _this = this;

        return xhr = new Request({
          onRequest: function() {
            _this.fireEvent('onRequest');
            return document.body.style.cursor = "wait";
          },
          onSuccess: function(responseText) {
            var json, refresh, url;

            if (refresh = xhr.getHeader('Refresh')) {
              console.log(refresh);
              url = refresh.split('=')[1];
              return window.location = url;
            }
            _this.fireEvent('onXHRSuccess');
            document.body.style.cursor = "";
            json = JSON.decode(responseText);
            if (json.html != null) {
              _this.changeState(json);
              return window.history.pushState(json, json.title, json.url);
            }
          },
          onFailure: function(response) {
            return document.documentElement.innerHTML = response.response;
          }
        });
      };

      AjaxNav.prototype.onPop = function(event) {
        this.fireEvent('onPopState');
        return this.changeState(event.state);
      };

      AjaxNav.prototype.onEvent = function(event) {
        if (event.shift || event.alt || event.meta || event.event.defaultPrevented) {
          return;
        }
        event.preventDefault();
        switch (event.type) {
          case 'click':
            return this.onClick(event);
          case 'submit':
            return this.onSubmit(event);
        }
      };

      AjaxNav.prototype.onClick = function(event) {
        var href;

        if (event.target.tagName === 'A') {
          href = event.target.href;
        } else {
          href = event.target.getParent('a').href;
        }
        return this.loadPage(href);
      };

      AjaxNav.prototype.onSubmit = function(event) {
        var form;

        if (event.target.tagName === 'FORM') {
          form = event.target;
        } else {
          form = event.target.getParent('form');
        }
        if (this.xhr.isRunning()) {
          return;
        }
        return this.xhr.send({
          url: form.action,
          data: form
        });
      };

      AjaxNav.prototype.unloadRequireScripts = function(cb) {
        var onUnloadError, onUnloadSuccess;

        onUnloadSuccess = function() {
          var module, modules, _i, _len, _results;

          modules = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
          _results = [];
          for (_i = 0, _len = modules.length; _i < _len; _i++) {
            module = modules[_i];
            if ((module != null) && typeof module.unload === 'function') {
              _results.push(module.unload());
            } else {
              _results.push(void 0);
            }
          }
          return _results;
        };
        onUnloadError = function(error) {
          return console.error('AjaxNav: RequireJS unloadRequireScripts', error);
        };
        console.log('unload', this.activeState.requireScripts);
        requirejs(this.activeState.requireScripts, onUnloadSuccess, onUnloadError);
        if (typeof cb === 'function') {
          return cb();
        }
      };

      AjaxNav.prototype.removePageStyles = function(state) {
        var href, _i, _len, _ref, _results;

        if (state.stylesheets != null) {
          _ref = state.stylesheets;
          _results = [];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            href = _ref[_i];
            console.log('removing stylesheet', "link[href*='" + href + "']");
            _results.push($$("link[href*='" + href + "']").destroy());
          }
          return _results;
        }
      };

      AjaxNav.prototype.loadScripts = function(state, cb) {
        var loadScriptsError, loadScriptsSuccess;

        if ((state.scripts != null) && state.scripts.length > 0) {
          loadScriptsSuccess = cb;
          loadScriptsError = function(error) {
            console.warn("AjaxNav loadScripts: RequireJS failed to load scripts due to " + error.requireType, error.requireModules);
            return loadScriptsSuccess();
          };
          return requirejs(state.scripts, loadScriptsSuccess, loadScriptsError);
        } else {
          return cb();
        }
      };

      AjaxNav.prototype.injectStylesheet = function(href) {
        var stylesheet;

        stylesheet = document.createElement('link');
        stylesheet.setAttribute('rel', 'stylesheet');
        stylesheet.setAttribute('type', "text/css");
        stylesheet.setAttribute('href', href);
        return this.head.appendChild(stylesheet);
      };

      AjaxNav.prototype.loadContent = function(state) {
        var href, _i, _len, _ref;

        if (state.stylesheets != null) {
          _ref = state.stylesheets;
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            href = _ref[_i];
            this.injectStylesheet(href);
          }
        }
        this.content.set('html', state.html);
        this.activeState = state;
        requirejs(state.requireScripts, function() {
          var module, modules, _j, _len1, _results;

          modules = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
          _results = [];
          for (_j = 0, _len1 = modules.length; _j < _len1; _j++) {
            module = modules[_j];
            if ((module != null) && typeof module.load === 'function') {
              _results.push(module.load());
            } else {
              _results.push(void 0);
            }
          }
          return _results;
        });
        return this.fireEvent('onContentLoaded');
      };

      AjaxNav.prototype.changeState = function(state) {
        var _this = this;

        if (state == null) {
          state = this.defaultState;
        }
        window.scrollTo(0, 0);
        document.title = state.title;
        if (typeof _gaq !== "undefined" && _gaq !== null) {
          _gaq.push(['_trackPageview', state.url]);
        }
        return this.unloadRequireScripts(function() {
          return _this.loadScripts(state, function() {
            _this.removePageStyles(_this.activeState);
            return _this.loadContent(state);
          });
        });
      };

      AjaxNav.prototype.loadPage = function(url) {
        if (url === window.location.href) {
          window.location.reload();
        }
        if (this.xhr.isRunning()) {
          this.xhr.cancel();
        }
        return this.xhr.send({
          url: url,
          method: 'get'
        });
      };

      return AjaxNav;

    })(EventEmitter);
    return ajaxNav = new AjaxNav();
  });

}).call(this);
