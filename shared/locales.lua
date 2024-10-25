-- Loads a specific locale file based on the given locale.
-- If the file is not found, falls back to the default "en" locale.
---@param locale string The desired locale.
---@return table The loaded locale data.
local function loadLocaleFile(locale)
    local resourceName = cache.resource
    local file = LoadResourceFile(resourceName, ("locales/%s.json"):format(locale))
    if not file then
        file = LoadResourceFile(resourceName, "locales/en.json")
        CreateThread(function()
            print(("Locale file \"%s\" not found, falling back to default \"en\"."):format(locale))
        end)
    end
    return json.decode(file) or {} -- JSON dosyasını tablo olarak yükle ve hata durumunda boş tablo döndür
end

-- Loads the default or user-configured locale and stores the data.
locales = loadLocaleFile(Config.Locale or "en")
