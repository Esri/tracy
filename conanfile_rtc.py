from conans import ConanFile


class TracyConan(ConanFile):
    name = "tracy"
    version = "0.13.1"
    url = "https://github.com/Esri/tracy/tree/runtimecore"
    license = "https://github.com/Esri/tracy/blob/runtimecore/LICENSE"
    description = (
        "A real time, nanosecond resolution, remote telemetry frame profiler for games and other applications."
    )

    # RTC specific triple
    settings = "platform_architecture_target"

    def package(self):
        base = self.source_folder + "/"
        relative = "3rdparty/tracy"

        # headers
        self.copy("Tracy.hpp", src=base + "/public/tracy", dst=relative + "/public/tracy")
        self.copy("TracyD3D11.hpp", src=base + "/public/tracy", dst=relative + "/public/tracy")
        self.copy("TracyMetal.hmm", src=base + "/public/tracy", dst=relative + "/public/tracy")
        self.copy("TracyOpenGL.hpp", src=base + "/public/tracy", dst=relative+ "/public/tracy")
        self.copy("*.h*", src=base + "/public/client", dst=relative + "/public/client")
        self.copy("*.h*", src=base + "/public/common", dst=relative + "/public/common")

        # libraries
        # TODO if mobile spit out static library in /staticlib
        output = "output/" + str(self.settings.platform_architecture_target) + "/bin"
        self.copy("*" + self.name + "*", src=base + "../../" + output, dst=output)
        output = "output/" + str(self.settings.platform_architecture_target) + "/staticlib"
        self.copy("*" + self.name + "*", src=base + "../../" + output, dst=output)
