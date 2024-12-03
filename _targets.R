# Load R functions
for (script in list.files(here::here("R"), full.names = TRUE)) {
  source(script)
}

# Track languageserver?
languageserver::run

library(targets)
library(tarchetypes)
library(xaringanthemer)

rlang::list2(
  tar_file(
    theme,
    theme_file(
      style_mono_accent(
        base_color = "#0c2a41",
        header_font_google = google_font("Playfair Display"),
        text_font_google = google_font("Montserrat", "300", "300i", "500", "500i", "600", "600i"), # nolint
        code_font_google = google_font("Fira Mono"),
        colors = c(
          red = "#c50f3c",
          yellow = "#ecaa00"
        )
      ),
      style_extra_css(
        css = list(
          ":root" = list(
            "--header-h1-font-size" = "3rem",
            "--header-h2-font-size" = "2rem",
            "--font12" = "12pt",
            "--font10" = "10pt"
          ),
          "h2, h3" = list(
            "font-family" = "var(--text-font-family)"
          ),
          ".font12" = list(
            "font-size" = "var(--font12) !important"
          ),
          ".font12 .remark-code" = list(
            "font-size" = "var(--font12) !important"
          ),
          ".font10" = list(
            "font-size" = "var(--font10) !important"
          ),
          ".font10 .remark-code" = list(
            "font-size" = "var(--font10) !important"
          ),
          ".ties-footer" = list(
            position = "fixed",
            bottom = 0,
            "text-align" = "left"
          ),
          ".ties-footer p img" = list(
            width = "30%"
          ),
          ".definition" = list(
            "background-color" = "#bde9fd",
            padding = "1%",
            border = "1px solid"
          )
        )
      )
    )
  ),
  tar_files_copy(
    move_theme,
    theme,
    here::here("www/xaringan-themer.css")
  ),
  tar_file(
    site_config,
    here::here("www/_site.yml")
  ),
  tar_target(
    site_deps,
    rlang::list2(
      move_theme,
      site_config,
    )
  ),
  tar_target(
    build_site,
    {
      site_deps
      rmarkdown::render_site(
        input = here::here("www"),
        quiet = TRUE
      )
    },
    cue = tar_cue_force(TRUE)
  ),
)
