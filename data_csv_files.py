import pandas as pd
from sqlalchemy import create_engine
import sqlalchemy


# Now, you can connect to the new 'painting' database using your original connection string and logic.
conn_string = 'postgresql://postgres:postgres@localhost:5432/painting_db'

db = create_engine(conn_string)
conn = db.connect()

files = ['artist', 'canvas_size', 'image_link', 'museum_hours', 'museum', 'product_size', 'subject', 'work']

for file in files:
    df = pd.read_csv(f'Resources/{file}.csv')
    print(df)
    df.to_sql(file, con=conn, if_exists='replace', index=False)