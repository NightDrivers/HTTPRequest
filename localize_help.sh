# 用于根据代码翻译文本刷新翻译配置文件，并将最新的配置文件导出用于翻译补充
for item in "en" "fr" "ja" "zh-Hant" "ko" "ru"
do
    STRINGS_PATH="HTTPRequest/${item}.lproj/Localizable.strings"
	cm_swift_localizer "HTTPRequest/" "${STRINGS_PATH}"  -textSuffix ".hr_localized" -verbose
done
