# base packages needed for sphinx...
base-packages:
    pkg.installed:
        - pkgs:
            - python-dev
            - python-pip
            - texlive
            - texlive-latex-extra
            - git-core
            - make
            - nginx
            
# install virtualenvwrapper via pip, not really needed but handy...
virtualenvwrapper:
    pip.installed:
        - require:
            - pkg: base-packages
            
# make sure the user sphinx exists
sphinx:
    user.present:
        - home: /home/sphinx

# create a virtual env
sphinx-venv:
    virtualenv.managed:
        - name: /home/sphinx/virtualenv
        - runas: sphinx
        - require:
            - user: sphinx

# install the requirements in the virtual env            
sphinx-pip:
    pip.installed:
        - bin_env: /home/sphinx/virtualenv
        - requirements: salt://sphinx-req.txt
        - runas: sphinx
        - require:
            - virtualenv: sphinx-venv

docs-git:
    git.latest:
        - name: https://github.com/bdejong/doctest.git
        - target: /home/sphinx/docs
        - runas: sphinx
        - require:
            - pkg: base-packages
            - pip: sphinx-pip
            - user: sphinx
            
/home/sphinx/docs/build/latex:
    file.directory:
        - user: sphinx
        - group: sphinx
        - makedirs: True
        - require:
            - git: docs-git
        
/home/sphinx/docs/build/html:
    file.directory:
        - user: sphinx
        - group: sphinx
        - makedirs: True
        - require:
            - git: docs-git

make-tex:
    cmd.run:
        - name: |
            rm -rf build/latex/*
            ~/virtualenv/bin/sphinx-build -b latex -D latex_paper_size=A4 -d build/doctrees source build/latex
        - cwd: /home/sphinx/docs/
        - user: sphinx
        - require:
            - file: /home/sphinx/docs/build/latex
    
make-pdf:
    cmd.run:
        - name: make all-pdf
        - cwd: /home/sphinx/docs/build/latex
        - user: sphinx
        - require:
            - cmd: make-tex

make-html:
    cmd.run:
        - name: |
            rm -rf build/html/*
            ~/virtualenv/bin/sphinx-build -b html -d build/doctrees source build/html
        - cwd: /home/sphinx/docs/
        - user: sphinx
        - require:
            - file: /home/sphinx/docs/build/html
            
# set up an nginx server to host the files...
/var/www/html:
    file.directory:
        - user: www-data
        - group: www-data
        - makedirs: True

/var/www/pdf:
    file.directory:
        - user: www-data
        - group: www-data
        - makedirs: True
            
/etc/nginx/sites-enabled/sphinx-nginx.conf:
    file.managed:
        - source: salt://sphinx-nginx.conf
        - user: root
        - group: root
        - require:
            - file: /var/www/html
            - file: /var/www/pdf
            - pkg: base-packages

nginx-service:
    service.running:
        - name: nginx
        - enable: True
        - require:
            - file: /etc/nginx/sites-enabled/sphinx-nginx.conf
            - pkg: base-packages
        - watch:
            - file: /etc/nginx/sites-enabled/sphinx-nginx.conf
            
copy-pdf:
    cmd.run:
        - name: |
            cp /home/sphinx/docs/build/latex/Documentationtest.pdf /var/www/pdf/Documentationtest.pdf 
            chown www-data:www-data /var/www/pdf/Documentationtest.pdf
        - require:
            - service: nginx-service
            - cmd: make-pdf
        
copy-html:
    cmd.run:
        - name: |
            cp -R /home/sphinx/docs/build/html/* /var/www/html/
            chown -R www-data:www-data /var/www/html
        - require:
            - service: nginx-service
            - cmd: make-html