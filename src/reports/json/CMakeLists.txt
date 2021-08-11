if(bactria_JSON_PLUGINS)
    add_library(bactria_reports_json MODULE Reports.cpp)
    target_link_libraries(bactria_reports_json PRIVATE bactria nlohmann_json::nlohmann_json)

    bactria_install_plugin(bactria_reports_json)
endif()
