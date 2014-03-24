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

void SetArrayVariable(
	const tstring & name,
	int id,
	const tstring & line
	)
{
	tcout << L"set \"";
	tcout << name;
	tcout << L"[" << id << "]";
	tcout << L"=" << line;
	tcout << L"\"" << std::endl;
}

void FillArray(
	const std::vector<tstring> & info,
	const tstring & name,
	const tstring & file,
	int & id
	)
{
	if(info.size() == 0) return;

	auto it = info.begin();
	size_t indention = 0;
	unsigned int nlc = 0;

	std::wifstream infile(file.c_str(), std::ifstream::in);

	if(!infile)
	{
	#ifdef _DEBUG
		tcout << file.c_str() << std::endl;
		tcout << strerror(errno) << std::endl;
	#endif
		return;
	}

	tstring line;
	int counter = 1;
	while (std::getline(infile, line))
	{
		size_t cpos = line.find('[');
		if(cpos == tstring::npos)
		{
			cpos = line.find_first_not_of(L" \t\r\n");
		}
		if(nlc++ == 0 || cpos == indention)
		{
			indention = cpos;
			if(it == info.end())
			{
				size_t pos = line.find(L'=') + 1;
				SetArrayVariable(
					name, id++,
					line.substr(pos, line.size() - pos)
					);
				++counter;
			}
			else if(line.find(*it) != tstring::npos)
			{
				++it;
				nlc = 0;
			}
		}
		else if(counter > 1)
		{
			return;
		}
	}

	infile.close();
	return;
}

int _tmain(int argc, _TCHAR* argv[])
{
	if(argc == 1)
		return ErrorReport(L"Please specify a localisation file.");
	else if(argc == 2)
		return ErrorReport(L"Please specify the name of the array");
	else if(argc == 3)
		return ErrorReport(L"Please specify the counter parameter");
	else if(argc == 4)
		return ErrorReport(L"Please specify one or more categories you are looking for.");

	tstring file, name, counter_name;
	file = argv[1];
	name = argv[2];
	counter_name = argv[3];
	int id = 1;

	for(int i = 4 ; i < argc ; ++i)
	{
		std::vector<tstring> information;
		GetHashInfo(argv[i], information);
		FillArray(information, name, file, id);
	}

	tcout << L"set \"" << counter_name << L"=" << (id - 1) << L"\"";

	return 0;
}
