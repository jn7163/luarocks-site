class AddToManifest extends require "widgets.base"
  content: =>
    h2 "Add Module To Manifest"
    
    @render_modules { @module }

    a href: @url_for("module", @), ->
      raw "&laquo; Return to module"

    h3 "Add To"
    if next @manifests
      @add_form!
    else
      text "There are no manifests this module can be added to at this time."

  add_form: =>
    form action: @req.cmd_url, method: "POST", ->
      div class: "input_row", ->
        label "Manifests"
        element "select", name: "manifest_id", ->
          for m in *@manifests
            option value: m.id, m.name

      input type: "submit", value: "Add Module"
