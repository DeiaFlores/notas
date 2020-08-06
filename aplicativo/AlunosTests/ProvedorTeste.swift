//
//  ProvedorTeste.swift
//  AlunosTests
//
//  Created by Julio Flores on 11/08/20.
//  Copyright © 2020 Julio Flores. All rights reserved.
//

import Foundation
@testable import Alunos

class ProvedorTeste: ProvedorAluno {
	enum Chamada: String {
		case existentes
		case novos
	}

	struct TipoTeste: OptionSet {
		let rawValue: Int

		static let novos = TipoTeste(rawValue: 1 << 0)
		static let existentes = TipoTeste(rawValue: 1 << 1)
		static let ambos: TipoTeste = [novos, existentes]
	}

	private static func aluno(nomeArquivo: String) -> Aluno {
		let pacote = Bundle(for: ProvedorTeste.self)
		let URLArquivo = pacote.url(forResource: nomeArquivo, withExtension: "json")!
		let dadosAluno = try! Data(contentsOf: URLArquivo)
		let decoder = JSONDecoder()
		return try! decoder.decode(Aluno.self, from: dadosAluno)
	}

	lazy var aluno1: Aluno = ProvedorTeste.aluno(nomeArquivo: "aluno1")

	lazy var aluno2: Aluno = ProvedorTeste.aluno(nomeArquivo: "aluno2")

	lazy var aluno3: Aluno = ProvedorTeste.aluno(nomeArquivo: "aluno3")

	lazy var aluno4: Aluno = ProvedorTeste.aluno(nomeArquivo: "aluno4")

	private var alunosNovosChamados = 0

	private let teste: TipoTeste

	init(teste: TipoTeste) {
		self.teste = teste
	}

	private func providenciarAlunosExistentes() throws -> Data {
		let dados = [self.aluno1, self.aluno2]
		let codificador = JSONEncoder()
		return try codificador.encode(dados)
	}

	private func providenciarAlunosNovos() throws -> Data? {
		let aluno: Aluno
		self.alunosNovosChamados += 1
		if self.alunosNovosChamados == 1 {
			aluno = self.aluno3
		} else if self.alunosNovosChamados == 2 {
			aluno = self.aluno4
		} else {
			return nil
		}

		let codificador = JSONEncoder()
		return try codificador.encode(aluno)
	}

	func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
		DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
			do {
				guard let url = request.url else {
					assertionFailure("Não é possível compreender a url dentro deste pedido: \(request)")
					return
				}
				guard let chamada = Chamada(rawValue: url.lastPathComponent) else {
					assertionFailure("Não é possivel compreender o pedido dentro da URL \(url)")
					return
				}

				let dados: Data
				if chamada == .novos && self.teste.contains(.novos) {
					guard let d = try self.providenciarAlunosNovos() else {
						return
					}
					dados = d
				} else if chamada == .existentes && self.teste.contains(.existentes) {
					dados = try self.providenciarAlunosExistentes()
				} else {
					return
				}

				let resposta = URLResponse(url: url, mimeType: "application/json", expectedContentLength: dados.count, textEncodingName: "utf-8")
				completionHandler(dados, resposta, nil)
			} catch let erro {
				completionHandler(nil, nil, erro)
			}
		}
		return URLSession.shared.dataTask(with: request)
	}
}
