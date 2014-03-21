#include "stdafx.h"
#include <iostream>
#include <fstream>
#include <vector>
#include <sstream>
#include <string>

#define tstring std::wstring
#define tcout std::wcout

static const tstring DEF_URL = L"http://www.google.com";

int ErrorReport(const tstring & str, int value = 0)
{
	tcout << str.c_str();
	return value;
}

void GetHashInfo(tstring id, std::vector<std::wstring> & info) {
	while(id.size() > 0)
	{
		size_t pos = id.find(L'-');
		
		tstring substr =
			id.substr(0, pos == tstring::npos ? id.length() : pos);
		info.push_back(substr);
		
		if(pos == tstring::npos) id = L"";
		else
		{
			++pos;
			id = id.substr(pos, id.length() - pos);
		}
	}
}

std::wstring GetText(const std::vector<tstring> & info, const tstring & file)
{
	if(info.size() == 0) return DEF_URL;

	auto it = info.begin();
	auto last = info.end() - 1;
	size_t indention = 0;
	unsigned int nlc = 0;

	std::wifstream infile(file.c_str(), std::ifstream::in);

	if(!infile)
	{
	#ifdef _DEBUG
		tcout << file.c_str() << std::endl;
		tcout << strerror(errno) << std::endl;
	#endif
		return DEF_URL;
	}

	tstring line;
	while (std::getline(infile, line))
	{
		size_t cpos = line.find('[');
		if(nlc++ == 0 || cpos == indention)
		{
			indention = cpos;
			if(line.find(*it) != tstring::npos)
			{
				if(it == last)
				{
					size_t pos = line.find(L'=') + 1;
					infile.close();
					return line.substr(pos, line.size() - pos);
				}
				else
				{
					++it;
					nlc = 0;
				}
			}
		}
	}

	infile.close();
	return DEF_URL;
}

int _tmain(int argc, _TCHAR* argv[])
{
	if(argc == 1)
		return ErrorReport(L"Please specify a localisation file.");
	else if(argc == 2)
		return ErrorReport(L"Please specify the ID you are looking for.");

	tstring file, hash;
	file = argv[1];
	hash = argv[2];

	std::vector<tstring> information;
	GetHashInfo(hash, information);

	tcout << GetText(information, file);

	return 0;
}
