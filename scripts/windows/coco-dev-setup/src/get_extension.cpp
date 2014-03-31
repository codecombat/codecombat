#include "stdafx.h"
#include <iostream>
#include <fstream>
#include <vector>
#include <sstream>
#include <string>

#define tstring std::wstring
#define tcout std::wcout

int ErrorReport(const tstring & str, int value = 0)
{
	tcout << str.c_str();
	return value;
}

int _tmain(int argc, _TCHAR* argv[])
{
	if(argc == 1)
		return ErrorReport(L"Please specify a download URL.");
	if(argc == 2)
		return ErrorReport(L"Please specify a name for your variable.");

	tstring url, name, extension;
	url = argv[1];
	name = argv[2];

	if(url.find(L"exe") != tstring::npos) extension = L"exe";
	else if(url.find(L"msi") != tstring::npos) extension = L"msi";
	else if(url.find(L"zip") != tstring::npos) extension = L"zip";

	tcout << L"set \"" << name << L"=";
	tcout << extension <<  L"\"";

	return 0;
}