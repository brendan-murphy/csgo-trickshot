#include <iostream>
#include <fstream>
#include <string>
#include <sys/types.h>
#include <sys/stat.h>

using namespace std;

bool FolderExist(const char * path){
	struct stat info;

	if (stat(path, &info) != 0){
		return false;
	}
	else if (!(info.st_mode & S_IFDIR)){
		return false;
	}
	return true;
}

int main(int argc, char* argv[]){
	string sourcePath;
	string csInstallPath;
	string pluginName;
	const string ACCESS_ERROR_MESSAGE = "Make sure your paths are set correctly and that SourceMod is installed properly.";

	if (argc > 2){ //source and install specified
		sourcePath = argv[1];
		csInstallPath = argv[2];
	}
	
	else if (!fstream("config.cfg")){
		cout << "No config file." << endl;
		cout << "Enter file path to plugin SourcePawn scrip" << endl;
		getline(cin, sourcePath);
		cout << "Enter file path to CS:GO root folder." << endl;
		getline(cin, csInstallPath);
		
		ofstream oconfigFile;
		oconfigFile.open("config.cfg");
		oconfigFile << sourcePath << endl;
		oconfigFile << csInstallPath << endl;
		oconfigFile.close();
		cout << "Config file is set up!" << endl << endl;
	}

	else{
		ifstream iconfigFile;
		iconfigFile.open("config.cfg");
		cout << "Loading config defaults" << endl;
		getline(iconfigFile, sourcePath);
		getline(iconfigFile, csInstallPath);
		iconfigFile.close();
	}

	if (sourcePath.length() <= 3 || sourcePath.substr(sourcePath.length() - 3, 3) != ".sp"){
		sourcePath = sourcePath + ".sp";
	}

	size_t lastSlash = sourcePath.find_last_of('\\');
	pluginName = sourcePath.substr(lastSlash + 1);
	pluginName = pluginName.substr(0, pluginName.length() -3);

	cout << "Beginning build process" << endl;

	// check for source file
	if (!fstream(sourcePath)){
		cout << "SourcePawn file could not be found" << endl;
		return -1;
	}

	// check for scripting folder
	if (!FolderExist((csInstallPath + "\\csgo\\addons\\sourcemod\\scripting").c_str())){
		cout << csInstallPath + "\\csgo\\addons\\sourcemod\\scripting cannot be accessed. " + ACCESS_ERROR_MESSAGE << endl;
		return -1;
	}

	//check for compiled folder
	if (!FolderExist((csInstallPath + "\\csgo\\addons\\sourcemod\\scripting\\compiled").c_str())){
		cout << csInstallPath + "\\csgo\\addons\\sourcemod\\scripting\\compiled cannot be accessed. " + ACCESS_ERROR_MESSAGE << endl;
		return -1;
	}
	
	//check for plugin folder
	if (!FolderExist((csInstallPath + "\\csgo\\addons\\sourcemod\\plugins").c_str())){
		cout << csInstallPath + "\\csgo\\addons\\sourcemod\\plugins cannot be accessed. " + ACCESS_ERROR_MESSAGE << endl;
		return -1;
	}

	// check for compiler
	if (!fstream(csInstallPath + "\\csgo\\addons\\sourcemod\\scripting\\compile.exe")){
		cout << "SourcePawn compiler could not be found. " + ACCESS_ERROR_MESSAGE << endl;
		return -1;
	}

	// check for prexisting script in scripting folder
	if (fstream(csInstallPath + "\\csgo\\addons\\sourcemod\\scripting\\" + pluginName + ".sp")){
		cout << "removed previous script from " + csInstallPath + " \\csgo\\addons\\sourcemod\\scripting\\" + pluginName + ".sp" << endl;
	}
	else{
		cout << "no previous script found in " + csInstallPath + "\\csgo\\addons\\sourcemod\\scripting\\"+ pluginName + ".sp" << endl;
	}

	//Copy source script
	ifstream  src(sourcePath, ios::binary);
	ofstream  dst(csInstallPath + "\\csgo\\addons\\sourcemod\\scripting\\" + pluginName + ".sp", ios::binary);
	dst << src.rdbuf();

	// Get when the plugin file was last modified
	//compile the script
	// If the last modifed date hasn't changed, then the compile failed

	//Move compiled plugin into the plugin folder
	//Done!

	return 0;
	
}