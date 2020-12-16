#include <iostream>
#include <string>
#include <vector>

extern "C" {
void printstr(std::string str) { std::cout << str << std::endl; }
void printstrref(std::string &str) { std::cout << str << std::endl; }
void printstrconstref(std::string const &str) { std::cout << str << std::endl; }

std::string returnstr() { return "test"; }
std::string returnlongstr() { return "longtestlongtestlongtestlongtestlongtest"; }

std::vector<int> returnintvec() { return {1, 2, 3}; }

void printintvec(std::vector<int> ints) {
  std::cout << "here" << std::endl;
  std::cout << ints.size() << std::endl;
  for (auto i : ints) {
    std::cout << i << " ";
  }
  std::cout << std::endl;
  std::cout << "dest" << std::endl;
}
void printintvecref(std::vector<int> &ints) {
  for (auto i : ints) {
    std::cout << i << " ";
  }
  std::cout << std::endl;
}

void printstrvec(std::vector<std::string> &strs) {
  for (auto i : strs) {
    std::cout << i << " ";
  }
  std::cout << std::endl;
}
}