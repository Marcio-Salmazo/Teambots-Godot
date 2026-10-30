# Como contribuir com o my-shadow

Este guia explica como baixar o projeto e desenvolver a sua parte. O jogo fica em `JOGO - TeamBots/Desenvolvimento/`. A pasta `TCC/` tem outro projeto Godot, que não faz parte do jogo: não abra nem altere.

## 1. O que instalar

- **Git.** No Windows, o Git Bash ou o PowerShell servem; os comandos abaixo são iguais.
- **Godot 4.7-stable**, a mesma versão para todos. Outra versão pode reescrever arquivos do projeto ao abrir e gerar mudanças que você não fez.
- Uma conta no GitHub com **acesso de escrita** a este repositório. Peça ao Márcio para adicionar você em *Settings → Collaborators*. Sem esse acesso você não consegue enviar branches nem aprovar PRs de outras pessoas.

## 2. Baixar e abrir

```bash
git clone https://github.com/Marcio-Salmazo/Teambots-Godot.git
cd Teambots-Godot
```

No Godot, clique em **Importar**, escolha `JOGO - TeamBots/Desenvolvimento/project.godot` e abra o projeto.

A primeira abertura reimporta os assets e cria a pasta `.godot/`. Demora um pouco, e essa pasta não vai para o Git.

Os nomes das pastas têm espaços, então use aspas nos caminhos. Para os comandos de Git abaixo, entre na pasta do jogo:

```bash
cd "JOGO - TeamBots/Desenvolvimento"
```

## 3. Rodar

- **F5** roda a cena principal, que hoje é o protótipo do Protagonista (`Protagonista/node_2d.tscn`).
- Para testar a Sombra, abra `Sombra/node_2d.tscn` e aperte **F6**.
- O painel **Depurador** deve ficar sem erros.

## 4. Fluxo para cada tarefa

**Regra de ouro: ninguém faz push direto na `main`.** O repositório bloqueia o merge sem 1 aprovação.

```bash
# 1. Atualize a main
git switch main
git pull

# 2. Crie a branch da tarefa (formato tipo/assunto)
git switch -c feature/nome-da-tarefa

# 3. Trabalhe no Godot e salve tudo (Ctrl+S)

# 4. Confira o que mudou e adicione os arquivos, um a um
git status
git add caminho/do/arquivo

# 5. Commit (formato "módulo: o que foi feito")
git commit -m "menu: botões jogar e sair"

# 6. Traga as novidades da main ANTES de enviar
git pull --rebase origin main

# 7. Envie a branch
git push -u origin feature/nome-da-tarefa
```

Evite `git add .` e `git add -A`: eles arrastam mudanças acidentais feitas pelo Godot.

Se o rebase gerar conflito em arquivo `.tscn`, **não edite o texto à mão**. Rode `git rebase --abort` e chame o responsável pela Arquitetura (P1).

### Abrir o Pull Request

1. No GitHub, clique em **Compare & pull request** (base: `main`).
2. Dê um título e cole o modelo abaixo na descrição. Este repositório não preenche o modelo sozinho.
3. Em **Reviewers**, marque o revisor indicado pelo grupo.

```markdown
## O que mudou

## Como testar (qual cena abrir e o que apertar)

- [ ] Roda sem erros no painel Depurador
- [ ] Só mexi em arquivos do meu módulo (ou avisei o dono)
- [ ] Não mexi em project.godot (ou este PR é só sobre isso)
- [ ] Usei os nomes do contrato (ações, grupos, autoloads)
```

## 5. Regras do grupo

- PR pequeno, com 1 aprovação do revisor indicado.
- Um dono por cena e por arquivo. Precisa mexer no arquivo de outra pessoa? Avise o dono antes.
- `project.godot` só muda em PR curto, dedicado a isso.
- Os arquivos `.uid` e `.import` **são commitados**: apagá-los quebra referências de script e de recurso. A pasta `.godot/` não é (o `.gitignore` já cuida disso).
- Mova e renomeie arquivos pelo painel **FileSystem do Godot**, nunca pelo gerenciador de arquivos do sistema.
- Não altere o contrato da próxima seção sem consenso do grupo.

## 6. Contrato de código

P1 a P6 são os números da divisão de tarefas do grupo.

### Ações de entrada (Input Map)

| Ação | Teclas |
| :--- | :--- |
| `mover_esq` | `A` / Seta Esquerda |
| `mover_dir` | `D` / Seta Direita |
| `pular` | Espaço |
| `interagir` | `E` |
| `pausar` | `Esc` |
| `mover_cim` | `W` (Sombra, mira vertical do dash) |
| `mover_bai` | `S` (Sombra, mira vertical do dash) |
| `dash` | `Shift` / Botão direito do mouse (Sombra) |

`ui_left`, `ui_right` e `ui_accept` ficam reservados para a navegação dos menus.

### Camadas de física (2D)

| Camada | Nome | Quem usa | Mask (com quem colide) |
| :--- | :--- | :--- | :--- |
| 1 | `mundo` | chão e paredes (tiles) | - |
| 2 | `jogador` | corpo dos personagens | 1 |
| 3 | `interagivel` | objetos de interação | 2 |
| 4 | `gatilho` | Gatilho, KillZone, Checkpoint, FimDeFase, placa de pressão | 2 |

### Grupos

- `jogador`: os dois personagens (Sombra e Protagonista).
- `fase`: o nó raiz de toda fase criada.

### Autoloads

Registrados em *Project Settings*, estritamente nesta ordem:

| Ordem | Nome | Dono |
| :--- | :--- | :--- |
| 1 | `GameManager` | P1 |
| 2 | `Save` | P1 |
| 3 | `Transicao` | P1 |
| 4 | `Config` | P3 |
| 5 | `AudioManager` | P6 |
| 6 | `Dialogo` | P4 |
| 7 | `Pausa` | P3 |

Hoje só os três primeiros existem. Os demais entram em PR do respectivo dono.

### Animações

Todo personagem tem, no mínimo, as animações `parado`, `andando` e `pulando`.

## 7. Testes automatizados

Com o Godot disponível no terminal, a partir de `JOGO - TeamBots/Desenvolvimento`:

```bash
godot --headless --path . -s res://tests/teste_p1.gd -- tudo
godot --headless --path . -s res://tests/teste_p1.gd -- gravar
godot --headless --path . -s res://tests/teste_p1.gd -- ler
```

`gravar` e `ler` rodam em processos separados para provar que o save sobrevive a fechar e abrir o jogo. O script sai com código 0 se tudo passou e 1 se algo falhou. Para apagar o save durante os testes, use *Project → Open User Data Folder*.

## 8. Problemas comuns

- **O Depurador acusa ação de input inexistente.** Seu `project.godot` está desatualizado. Rode `git pull --rebase origin main`.
- **O Godot alterou arquivos que você não tocou.** Confira se está na versão 4.7. Para descartar uma mudança que não é sua: `git restore caminho/do/arquivo`.
- **Desempenho ruim na sua máquina.** O projeto usa o renderer Forward+. Avise o grupo antes de trocar para Compatibility, porque a mudança vale para todos.
