while True:
     nome = str(input('Informe o nome:'))
     sexo = str(input('Informe o sexo: [M/F] ')).strip().upper()[0]
     while sexo not in  'MmFf':
      sexo = str(input('Dados inválidos. Digite novamente ' ))
     n1 = float(input('Informe a primeira nota:'))
     if n1 < 0 or n1 > 10:
         print("A nota deve ser um valor entre zero e dez")
     n2 = float(input('Informe a segunda nota: '))
     if n2 < 0 or n2 > 10:
         print("A nota deve ser um valor entre zero e dez")
     n3 = float(input('Informe a terceira nota: '))
     if n3 < 0 or n3 > 10:
         print("A nota deve ser um valor entre zero e dez")

     media = (n1 + n2 + n3) / 3
     print(media)

     if media >= 7 and media <= 10:
        print("Estudante aprovado")
     elif media < 7.0 and media >= 4:
        print("Estudante Exame")
     else:
        print("Reprovado")



     sexof = 'f'
     sexom = 'm'
     print('A quantidade do sexo feminino é:', len(sexof))


     total_inscritos = len(sexof) + (len(sexom))
     print('O valor absoluto é : ', abs(total_inscritos))

     resp = ' '
     while resp not in 'SN':
         resp = str(input('deseja continuar?[S/N] ')).upper()