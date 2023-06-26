# NC State University Libraries ArchivesSpace scripts

This is a selection of of Ruby scripts that NC State University Libraries uses to manage data in ArchivesSpace.

## Things to know

1. This are Ruby scripts. You need to have Ruby installed on your computer (or Docker container, etc.) to run them, and have sufficient permissions to install gems (Ruby code libraries).
2. These scripts interact directly with the MySQL database used by ArchivesSpace, rather than interacting via the ArchivesSpace API. There are pros and cons to this approach, but we've found it to be well-suited to our needs and available resources.

## Things to do

1. Before you begin, you'll need to have this information available:
    a. MySQL database host
    b. MySQL databse port (probably 3306, so use that if you don't know)
    c. MySQL username + password (with read/write permissions on the ArchivesSpace database)
    d. ArchivesSpace database name
https://archivesspace.github.io/tech-docs/administration/indexes.html

