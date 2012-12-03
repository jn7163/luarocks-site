
class ModuleVersion extends require "widgets.base"
  rock_url: (item) =>
    "/manifests/#{@user\url_key!}/#{item\filename!}"

  content: =>
    h2 "#{@module.name} #{@version.version_name}"
    @admin_panel!

    div ->
      text "Downloads: "
      span class: "value", @format_number @version.downloads


    h2 "Available Downloads"
    ul class: "rock_list", ->
      li class: "arch", ->
        a href: @rock_url(@version), "rockspec"

      for rock in *@rocks
        li class: "arch", ->
          a href: @rock_url(rock), rock.arch

    a href: @url_for("module", user: @user.slug, module: @module.name), "Back To Module"

  admin_panel: =>
    return unless @module\allowed_to_edit @current_user

    div class: "admin_tools", ->
      span class: "label", "Admin: "

      url = @url_for "upload_rock", {
        user: @user.slug,
        module: @module.name
        version: @version.version_name
      }

      a href: url, "Upload Rock"


