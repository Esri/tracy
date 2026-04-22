project "tracy"

if (_PLATFORM_LINUX or _PLATFORM_MACOS or _PLATFORM_WINDOWS) then
  -- desktop platforms use a shared library to avoid initialization errors from using multiple shared libraries
  dofile(_BUILD_DIR .. "/shared_library.lua")
else
  dofile(_BUILD_DIR .. "/static_library.lua")
end

configuration { "*" }

uuid "82A366FD-C1E6-4BDC-A52E-DF8AC72763F8"

defines {
  "TRACY_ENABLE",
}

files {
  "public/TracyClient.cpp",
}

if (_PLATFORM_ANDROID) then
  defines { "TRACY_NO_CALLSTACK" }
end

if (_PLATFORM_IOS) then
end

if (_PLATFORM_LINUX) then
end

if (_PLATFORM_MACOS) then
end

if (_PLATFORM_WINDOWS) then
  defines { "TRACY_EXPORTS" }
end