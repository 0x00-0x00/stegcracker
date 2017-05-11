# Instalar
```bash
sudo cpan install Getopt::ArgParse
```

# Descricao
Brute-force que divide as wordlists em fragmentos de tamanhos identicos baseado no numero de nucleos fornecido pelo usuario, cada nucleo sera responsavel por cada fragmento da wordlist, reduzindo o tempo de brute-force em N vezez, onde N se da pelo numero de nucleos.

# Uso
Para utilizar 4 nucleos paralelos no brute-force:
```bash
./stegcrack.pl -w wordlist.txt -f stego.jpg --cores 4
```
