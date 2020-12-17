//
//  Aluno.swift
//  Alunos
//
//  Created by Julio Flores on 02/08/20.
//  Copyright © 2020 Julio Flores. All rights reserved.
//

import Combine
import Foundation

enum ErroAluno: Error {
	case urlErrada(String)
	case dadosIncorretos(Error?)
	case desconhecido(Error?)
}

struct Aluno: Equatable, Codable {
	enum Sexo: String, Codable {
		case masculino = "m"
		case feminino = "f"
	}
	
	let nome: String
	let sexo: Sexo
	let notas: [Float]
}

protocol ProvedorAluno {
	@discardableResult func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask
}

extension URLSession: ProvedorAluno {}

fileprivate class AssinaturaAluno: Subscription, Hashable {
	static func == (lhs: AssinaturaAluno, rhs: AssinaturaAluno) -> Bool {
		lhs.hashValue == rhs.hashValue
	}

	var hashValue: Int

	func hash(into hasher: inout Hasher) {
		hasher.combine(self.hashValue)
	}

	private let assinante: AnySubscriber<Aluno, ErroAluno>

	private var alunosProntos: [Aluno]

	private var alunosPedidos = 0

	private let deleter: ((AssinaturaAluno) -> Void)

	init(assinante: AnySubscriber<Aluno, ErroAluno>, alunosExistentes: [Aluno], deleter: @escaping ((AssinaturaAluno) -> Void)) {
		self.deleter = deleter
		self.assinante = assinante
		self.alunosProntos = alunosExistentes
		self.hashValue = Int.random(in: Int.min ... Int.max)
	}

	func enviar(aluno: Aluno) {
		self.alunosProntos.append(aluno)
		self.enviar()
	}

	func enviar(alunos: [Aluno]) {
		self.alunosProntos.append(contentsOf: alunos)
		self.enviar()
	}

	func enviar(erro: ErroAluno) {
		self.assinante.receive(completion: .failure(erro))
	}

	private func enviar() {
		let alunosAEnviar = min(self.alunosPedidos, self.alunosProntos.count)
		for _ in 0 ..< alunosAEnviar {
			_ = self.assinante.receive(self.alunosProntos.removeFirst())
		}
		self.alunosPedidos -= alunosAEnviar
	}

	func request(_ demand: Subscribers.Demand) {
		if let pedidos = demand.max {
			self.alunosPedidos = pedidos
		} else {
			self.alunosPedidos = Int.max
		}

		self.enviar()
	}

	func cancel() {
		self.assinante.receive(completion: .finished)
		self.deleter(self)
	}
}

class ControleAluno: Publisher {
	typealias Output = Aluno

	typealias Failure = ErroAluno

	private let preferencias: Preferencias

	private var alunos = [Aluno]()

	private var assinaturas = Set<AssinaturaAluno>()

	private static let conexaoPadrao: URLSession = {
		var configuracao = URLSessionConfiguration.default
		configuracao.timeoutIntervalForRequest = Date.distantFuture.timeIntervalSinceNow
		return URLSession(configuration: configuracao)
	}()

	init(preferencias: Preferencias, provedorAluno: ProvedorAluno = ControleAluno.conexaoPadrao) {
		self.preferencias = preferencias
		self.buscarAlunosNovos(provedor: provedorAluno)
		self.buscarAlunosExistentes(provedor: provedorAluno)
	}

	private func receberDados<Aluno: Decodable>(dados: Data?, erro: Error?) throws -> Aluno {
		guard let dados = dados else {
			if let erro = erro {
				throw erro
			} else {
				throw ErroAluno.dadosIncorretos(nil)
			}
		}

		do {
			let decoder = JSONDecoder()
			return try decoder.decode(Aluno.self, from: dados)
		} catch let erro {
			throw ErroAluno.dadosIncorretos(erro)
		}
	}

	private func buscarAlunosNovos(provedor: ProvedorAluno) {
		func buscarNovoAluno(resultado: (@escaping (Aluno?, Error?) -> Void)) {
			let enderecoAlunosNovos = "\(self.preferencias.enderecoServidor)/novos"

			guard let urlAlunosNovos = URL(string: enderecoAlunosNovos) else {
				resultado(nil, ErroAluno.urlErrada(enderecoAlunosNovos))
				return
			}

			let pedido = URLRequest(url: urlAlunosNovos)
			provedor.dataTask(with: pedido, completionHandler: { (dados, _, erro) in
				do {
					let novoAluno: Aluno = try self.receberDados(dados: dados, erro: erro)
					resultado(novoAluno, nil)
					buscarNovoAluno(resultado: resultado)
				} catch let erro {
					resultado(nil, erro)
				}
			})
		}

		DispatchQueue.global().async {
			buscarNovoAluno { (aluno, erro) in
				if let aluno = aluno {
					self.assinaturas.forEach({ $0.enviar(aluno: aluno) })
				} else if let erro = erro as? ErroAluno {
					self.assinaturas.forEach({ $0.enviar(erro: erro) })
				} else {
					let erroDesconhecido = ErroAluno.desconhecido(erro)
					self.assinaturas.forEach({ $0.enviar(erro: erroDesconhecido) })
				}
			}
		}
	}

	private func buscarAlunosExistentes(provedor: ProvedorAluno) {
		let enderecoAlunosExistentes = "\(self.preferencias.enderecoServidor)/existentes"

		guard let urlAlunosExistentes = URL(string: enderecoAlunosExistentes) else {
			let erro = ErroAluno.urlErrada(enderecoAlunosExistentes)
			self.assinaturas.forEach({ $0.enviar(erro: erro) })
			return
		}

		let pedido = URLRequest(url: urlAlunosExistentes)
		provedor.dataTask(with: pedido, completionHandler: { (dados, _, erro) in
			do {
				let alunos: [Aluno] = try self.receberDados(dados: dados, erro: erro)
				self.assinaturas.forEach({ $0.enviar(alunos: alunos) })
			} catch let epa as ErroAluno {
				self.assinaturas.forEach({ $0.enviar(erro: epa) })
			} catch let erro {
				let erroDesconhecido = ErroAluno.desconhecido(erro)
				self.assinaturas.forEach({ $0.enviar(erro: erroDesconhecido) })
			}
		})
	}

	func receive<S>(subscriber: S) where S : Subscriber, S.Failure == ErroAluno, S.Input == Aluno {
		let novaAssinatura = AssinaturaAluno(assinante: AnySubscriber<Aluno, ErroAluno>(subscriber), alunosExistentes: self.alunos, deleter: { [self] (assinaturaARemover) in self.assinaturas.remove(assinaturaARemover) })
		self.assinaturas.insert(novaAssinatura)
		subscriber.receive(subscription: novaAssinatura)
	}
}
