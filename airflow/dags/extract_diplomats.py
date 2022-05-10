import locale
import os
import re
from dataclasses import dataclass, replace, asdict
from datetime import datetime
from typing import Optional, Dict, Tuple

import pandas as pd
import pdfplumber
import pyarrow as pa


@dataclass
class Person:
    """Class for storing information on a person"""
    title: str
    gender: str
    name: str
    position_name: str = None
    date_since: str = None
    order: int = None 
    partner_gender: str = None
    partner_name: str = None



class ExtractDiplomats():

    def __init__(self, path, autostart=True) -> None:
        
        # open PDF
        self.pdf: pdfplumber.pdf.PDF = pdfplumber.open(path)

        # get date
        self.date: Optional[datetime.date] = self.extract_date()

        # create index with all countries and start and end page as tuple
        self.country_index: Dict[str, Tuple[int, Optional[int]]] = self.create_country_index()

        # extract data
        if autostart:
            self.df: pd.DataFrame = self.extract_data()


    def extract_date(self) -> Optional[datetime.date]:
        
        line: str
        for line in self.pdf.pages[0].extract_text().splitlines():

            if line.startswith('Stand:'):
                line = line.strip('Stand: ')
                locale.setlocale(locale.LC_TIME, "de_DE.UTF-8") 
                date: datetime.date = datetime.strptime(line, '%d. %B %Y').date()

                return date
    
    def create_country_index(self) -> Dict[str, Tuple[int, Optional[int]]]:
        
        # get_country_index
        country_index: Dict[str, Tuple[int, Optional[int]]] = {}

        # Start on page 2, because page 1 is the cover and would be a false positive
        page: pdfplumber.page.Page
        for page in self.pdf.pages[1:]:
            
            # split text on page into lines
            lines: list[str] = page.extract_text().splitlines()
            # if there is at least one line and the first line is uppercase
            if len(lines) and lines[0] == lines[0].upper():
                
                # set end page for previous country in tupel (index start page, index end page+1)
                if country_index:
                    country_index[country_name] = (country_index[country_name][0], page.page_number-1)
                
                # save country and page index (page number - 1) in index
                country_name: str = lines[0].title()
                country_index[country_name] = (page.page_number-1, None)
        
        return country_index


    def extract_data(self) -> pd.DataFrame:

        dfs: list[pd.DataFrame] = []

        for country in self.country_index.keys():
            dfs.append(self.extract_country(country))

        return pd.concat(dfs)
    

    def extract_country(self, name) -> pd.DataFrame:
        
        pages: list[str] = []
        country: Tuple[int, Optional[int]] = self.country_index[name]

        page: pdfplumber.page.Page
        for page in self.pdf.pages[slice(*country)]:
            pages.append(page.extract_text())
        
        lines: list[str] = '\n'.join(pages).splitlines()

        country_name: str = lines[0].title()

        if ':' not in lines[1]:
            country_name_long: str = lines[1]
        else:
            country_name_long = None

        people: Dict[int, Person] = self.extract_people(lines)

        df: pd.DataFrame = pd.json_normalize(asdict(obj) for obj in people.values())
        df['country'] = country_name
        df['country_long'] = country_name_long
        df['date'] = self.date

        return df
    

    def extract_people(self, lines) -> Dict[int, Person]:

        diplomats: Dict[int, Person] = {}
        order: int = 0

        idx: int
        line: str
        for idx, line in enumerate(lines):
            
            if line.lower().startswith(('s. e.', 'i. e.', 'herr', 'frau', '---')):
                # new name found
                if 'idx_last_found' in locals() and idx == idx_last_found + 1:
                    # new name follows after last name -> last name ist partner
                    # previous_person is diplomat
                    # person is partner
                    diplomats[previous_person_key] = replace(diplomats[previous_person_key], 
                                                    partner_gender=person.gender, 
                                                    partner_name=person.name)
                    del diplomats[person.order] # delete partner object
                    order -= 1
                    del idx_last_found
                
                if line.lower().startswith(('s. e.', 'i. e.')):
                    title: str = line[:5]
                    line = line[5:].strip()
                else:
                    title: Optional[str] = None

                if line.lower().startswith(('herr', 'frau')):

                    line = line.split(' ', maxsplit=1)
                    if len(line) != 2:
                        continue
                    
                    gender: str = line[0]
                    line = line[1]
                else:
                    gender = None

                name: str = line.strip('- ')

                idx_last_found: int = idx
                previous_person_key: int = order
                order += 1
                person = Person(title, gender, name, order=order)

                diplomats[order] = person
            
            elif re.search('\(\d{2}\.\d{2}\.\d{4}\)', line):
                # second line of person containing position and date
                
                line = line.split(',')

                position: str = ', '.join(line[:-1]).strip() # first part until the last comma
                date_since: str = line[-1].strip('() ') # date in brackers
                date_since: datetime.date = datetime.strptime(date_since, '%d.%m.%Y').date()

                order: int = person.order

                diplomats[order] = replace(person, 
                                                position_name=position, 
                                                date_since=date_since)
                            
            else:
                # if nothing was found in this line, reset 
                if 'idx_last_found' in locals() and idx == idx_last_found + 1:
                    idx_last_found: int = idx
                    

        # if last line was person -> this was a partner
        if 'idx_last_found' in locals() and idx == idx_last_found:
            diplomats[previous_person_key] = replace(diplomats[previous_person_key], 
                                                    partner_gender=person.gender, 
                                                    partner_name=person.name)
            del diplomats[person.order] # delete partner object

        return diplomats
    

    def to_csv(self, path, **kwargs):
        
        if not hasattr(self, 'df'):
            raise Exception('No data. Initialize class with autostart=True first.')

        kwargs['index'] = False
        self.df.to_csv(path, **kwargs)


    def to_parquet(self, path='', date_subdirectory=True, overwrite=True, **kwargs):
        
        if not hasattr(self, 'df'):
            raise Exception('No data. Initialize class with autostart=True first.')

        # default_subdirectory results in adding year/month/day to the path
        if date_subdirectory:
            path = os.path.join(path, str(self.date.year), '{:02d}'.format(self.date.month), '{:02d}'.format(self.date.day))

            # add parquet ending
            if not 'partition_cols' in kwargs:
                path += '.parquet'
        
        # otherwise create needed directories
        if not os.path.exists(os.path.dirname(path)):
            os.makedirs(os.path.dirname(path), exist_ok=True)

        
        kwargs['engine'] = 'pyarrow'
        kwargs['index'] = False
        kwargs['schema'] = pa.schema([('title', pa.string()),
                                      ('gender', pa.string()),
                                      ('name', pa.string()),
                                      ('position_name', pa.string()),
                                      ('date_since', pa.date32()),
                                      ('order', pa.uint16()),
                                      ('partner_gender', pa.string()),
                                      ('partner_name', pa.string()),
                                      ('country', pa.string()),
                                      ('country_long', pa.string()),
                                      ('date', pa.date32())
                                     ])
        
        self.df.to_parquet(path, **kwargs)


if __name__ == "__main__":
    
    for file in os.listdir("pdf"):
        if file.endswith("_data.pdf"):
            print(os.path.join("pdf", file))

            pdf = ExtractDiplomats(os.path.join("pdf", file))
            #pdf.to_csv('export.csv')
            pdf.to_parquet('data', date_subdirectory=True)