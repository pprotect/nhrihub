import { en } from "../../config/locales/views/projects/en.yml"
import { en as site_wide } from "../../../../../config/locales/views/site_wide/common_text/en.yml"
import { en as performance_indicators } from "../../../../../config/locales/views/shared/en.yml"
import { en as error_messages } from "../../../../../config/locales/views/site_wide/error_messages/en.yml"

var locale
I18n.locale = locale = window.current_locale;
if(typeof I18n.translations[locale] == 'undefined'){
  I18n.translations[locale] = {}
}

_.extend(I18n.translations.en, en.projects.projects_templates)
_.extend(I18n.translations.en, site_wide )
_.extend(I18n.translations.en, error_messages )
_.extend(I18n.translations.en, performance_indicators.shared.performance_indicator_select )

export default I18n.translations.en

