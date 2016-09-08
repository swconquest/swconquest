mkdir Data
mkdir Textures
mkdir Resource

ln -s ../main.bmp .
ln -s ../module.ini .

ln -s ../Languages languages
ln -s ../Music .
ln -s ../SceneObj .
ln -s ../Sounds .

ln -s ../../Font/FONT_DATA.XML Data/font_data.xml
ln -s ../../Font/FONT_SWC.dds  Textures/font.dds

cd Textures && ln -s ../../Textures/*.dds .
cd ..
cd Resource && ln -s ../../Resource/*.brf .
cd ..


ln -s ../map.txt .
