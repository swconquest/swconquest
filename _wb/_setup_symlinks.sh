mkdir Data
mkdir Textures
mkdir Resource

ln -s ../main.bmp .
ln -s ../module.ini .

ln -s ../Languages languages
ln -s ../Music .
ln -s ../Resource .
ln -s ../SceneObj .
ln -s ../Sounds .

ln -s ../../Font/FONT_DATA.XML Data/font_data.xml
ln -s ../../Font/FONT_SWC.dds  Textures/font.dds

cd Textures && ln -s ../../Textures/* .
cd ..
cd Resource && ln -s ../../Resource/* .
cd ..


ln -s ../map.txt .
