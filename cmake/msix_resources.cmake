# Create header for Appx certs

file(READ "${CMAKE_PROJECT_ROOT}/resources/certs/base64_MSFT_RCA_2010.cer"  BASE64_MSFT_RCA_2010)
file(READ "${CMAKE_PROJECT_ROOT}/resources/certs/base64_MSFT_RCA_2011.cer"  BASE64_MSFT_RCA_2011)
file(READ "${CMAKE_PROJECT_ROOT}/resources/certs/base64_STORE_PCA_2011.cer" BASE64_STORE_PCA_2011)
file(READ "${CMAKE_PROJECT_ROOT}/resources/certs/base64_Windows_Production.cer" BASE64_WINDOWS_PRODUCTION)
file(READ "${CMAKE_PROJECT_ROOT}/resources/certs/base64_Windows_Production_PCA_2011.cer" BASE64_WINDOWS_PRODUCTION_PCA_2011)
file(READ "${CMAKE_PROJECT_ROOT}/resources/certs/Microsoft_MarketPlace_PCA_2011.cer" BASE64_MSFT_MARKETPLACE_CA_G_016)

set(APPX_CERTS "// This file is generated by CMake and contains certs for parsing the AppxBlockMap.xml. Do not edit!!
#include <string>
#include <vector>

namespace MSIX {

// Do not alter the order of these certificates -- they are in chain order
std::vector<std::string> appxCerts = {
R\"(${BASE64_MSFT_RCA_2010})\",
R\"(${BASE64_WINDOWS_PRODUCTION_PCA_2011})\",
R\"(${BASE64_MSFT_RCA_2011})\",
R\"(${BASE64_STORE_PCA_2011})\",
R\"(${BASE64_MSFT_MARKETPLACE_CA_G_016})\",
R\"(${BASE64_WINDOWS_PRODUCTION})\",
};

}")
file(WRITE "${CMAKE_PROJECT_ROOT}/src/inc/AppxCerts.hpp" "${APPX_CERTS}")

# This file creates a zip file for our resources and produce two files (resource.hpp/cpp).
# Resource.cpp contains a std::vector<std::uint8_t> that is the zip file as bytes. Internally,
# we get the vector, treat as a stream and use our own ZipObject implementation to read data from it.

# Create zip file. Use execute_process to run the command while CMake is procesing. 
execute_process(
    COMMAND ${CMAKE_COMMAND} -E tar cfv "${CMAKE_BINARY_DIR}/resources.zip" --format=zip -- "AppxPackaging" "certs"
    WORKING_DIRECTORY "${CMAKE_PROJECT_ROOT}/resources"
)

file(READ "${CMAKE_BINARY_DIR}/resources.zip" RESOURCE_HEX HEX)
# Create a list by matching every 2 charactes. CMake separates lists with ;
string(REGEX MATCHALL ".." RESOURCE_HEX_LIST "${RESOURCE_HEX}")
# The list is just a string, so change ; for ", 0x" to initialize the vector.
# Just remember the first element won't have 0x.
string(REGEX REPLACE ";" ", 0x" RESOURCE_BYTES "${RESOURCE_HEX_LIST}") 

set(RESOURCE_HEADER "// This file is generated by CMake. Do not edit.
#include <vector>

namespace MSIX {
    namespace Resources { 
        extern std::vector<std::uint8_t> resourceByte;
    }
}
")
set(RESOURCE_CPP "// This file is generated by CMake. Do not edit.
#include \"resource.hpp\"

namespace MSIX {
    namespace Resources {
        std::vector<std::uint8_t> resourceByte = {0x${RESOURCE_BYTES}};
    }
}
")

file(WRITE "${CMAKE_PROJECT_ROOT}/src/inc/resource.hpp" "${RESOURCE_HEADER}")
file(WRITE "${CMAKE_PROJECT_ROOT}/src/msix/resource.cpp" "${RESOURCE_CPP}")
