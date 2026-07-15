// Behavioral test: parse → typed access → array/table nodes → _toml literal →
// serialize-and-reparse round-trip, all through the C++23 module surface
// (`import tomlplusplus;`, no #include).
import std;
import tomlplusplus;

int main() {
    auto cfg = toml::parse(R"(
        [server]
        host = "localhost"
        port = 8080
        tags = ["a", "b"]
    )");

    // typed access — value<std::string> so this compares strings, not pointers
    bool ok = cfg["server"]["port"].value<int>() == 8080
              && cfg["server"]["host"].value<std::string>() == "localhost"
              && cfg["server"]["tags"].as_array()->size() == 2;

    // the _toml literal re-exported through toml::literals
    using namespace toml::literals;
    auto lit = "x = 1"_toml;
    ok = ok && lit["x"].value<int>() == 1;

    // round-trip: serialize via the exported operator<<, then re-parse
    std::ostringstream os;
    os << cfg;
    auto again = toml::parse(os.str());
    ok = ok && again["server"]["port"].value<int>() == 8080
            && again["server"]["tags"].as_array()->size() == 2;

    return ok ? 0 : 1;
}
