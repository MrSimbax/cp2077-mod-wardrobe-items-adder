version="2.0.0"
current=`pwd`
path="bin/x64/plugins/cyber_engine_tweaks/mods/wardrobe_items_adder"
package_name="wardrobe_items_adder_v${version}"
package_path="${package_name}/${path}"
cd ..
mkdir -p "${package_path}"
cd "${current}"
find . -iname '*.lua' -type f -exec cp --parents {} "../${package_path}" \;
cd "../${package_name}"
rm "${path}/config.lua"
zip -r "../${package_name}.zip" .
