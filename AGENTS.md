# AGENTS.md

## Cursor Cloud specific instructions

### What this repo is
This is a **reference collection of open-source TRMNL plugins** (see `README.md`), not a runnable
application. Each plugin under `lib/<plugin>/` is a Ruby class (`<plugin>.rb`) plus ERB view
templates in `views/`. There is intentionally **no Gemfile, no test suite, no CI, no build system,
and no server to boot** — the code exists to show how values are extracted from 3rd-party APIs and
rendered into TRMNL screens.

Plugin classes inherit from a `Base` class and use Rails helpers (`t(...)`, `render`,
`instance_name`, `Rails.application.credentials`, `ActionController::Base.helpers`, etc.) that live
in TRMNL's **closed-source core Rails app** and are **not present here**. Therefore the plugin
classes and views **cannot execute standalone** without stubbing those helpers.

### Toolchain
- Ruby (3.2.x, system `ruby`/`gem`) is the only runtime needed. There are no per-repo package deps.
- `erubi` (Rails' ERB engine) is installed via the update script and is used to validate/render views.

### "Lint" / validation (there is no configured linter)
- Ruby syntax check every plugin file: `ruby -c lib/<plugin>/<file>.rb` (expect `Syntax OK`).
- ERB views use Rails' **raw-output tag `<%== ... %>`**, which the stock `erb` binary rejects.
  Validate views with Erubi instead, e.g.:
  `ruby -e "require 'erubi'; Dir.glob('lib/**/*.erb').each { |f| RubyVM::InstructionSequence.compile(Erubi::Engine.new(File.read(f), escape: true).src) }"`

### Rendering a plugin (the core functionality)
To "run" a plugin locally, build the `locals` hash the plugin's `#locals` method would return and
render the matching `views/*.html.erb` through Erubi, supplying stubs for the Rails helpers the view
calls (`t`, `render` for partials, `instance_name`, `Rails.application.credentials.base_url`).
Rails treats `render`/partial output as `html_safe`, so wrap partial output so it is not
re-HTML-escaped. The official TRMNL design CSS/JS (for accurate screenshots) is served from
`https://usetrmnl.com/css/latest/plugins.css` and `https://usetrmnl.com/js/latest/plugins.js`.

### Known pre-existing issue (do not "fix" as part of env setup)
`lib/route_planner/route_planner.rb` has a genuine Ruby **syntax error**: it mixes endless method
definitions (`def origin = "..."`) with redundant `end` keywords, which is invalid in any Ruby
version. All other 25 `.rb` files and all 139 `.erb` views pass validation.
