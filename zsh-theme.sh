git clone --depth=1 https://github.com/ryanoasis/nerd-fonts.git 
cd nerd-fonts
./install.sh
cd ..
rm -rf ./nerd-fonts
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
echo 'ZSH_THEME="powerlevel10k/powerlevel10k"' >> ~/.zshrc
