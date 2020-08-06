//
//  TestesAlunos.swift
//  AlunosTests
//
//  Created by Julio Flores on 11/08/20.
//  Copyright © 2020 Julio Flores. All rights reserved.
//

import XCTest
import Combine
@testable import Alunos

class TestesAlunos: XCTestCase {

	private let preferenciasTeste = Preferencias(enderecoServidor: "http://teste")

	let cuidarDoErro: ((Subscribers.Completion<ErroAluno>) -> Void) = { (finalInesperado) in
		if case .failure(let erroAluno) = finalInesperado {
			XCTFail("Deu algum erro ao testar assinaturas para receber alunos: \(erroAluno)")
		}
	}

	func testarBuscaExistentes() {
		// given
		let expectativa = expectation(description: "Alunos Existentes")
		let provedorTeste = ProvedorTeste(teste: .existentes)

		var alunos = [Aluno]()

		// when
		let controleAluno = ControleAluno(preferencias: preferenciasTeste, provedorAluno: provedorTeste)
		let cancelavel = controleAluno.sink(receiveCompletion: cuidarDoErro, receiveValue: { (aluno) in
			alunos.append(aluno)
			if alunos.count >= 2 {
				expectativa.fulfill()
			}
		})

		self.waitForExpectations(timeout: 1.0)

		// then
		XCTAssert(alunos.contains(provedorTeste.aluno1))
		XCTAssert(alunos.contains(provedorTeste.aluno2))

		// teardown
		cancelavel.cancel()
	}

	func testarBuscaNovos() {
		// given
		let expectativa = expectation(description: "Alunos Novos")
		let provedorTeste = ProvedorTeste(teste: .novos)

		var alunos = [Aluno]()

		// when
		let controleAluno = ControleAluno(preferencias: preferenciasTeste, provedorAluno: provedorTeste)
		let cancelavel = controleAluno.sink(receiveCompletion: cuidarDoErro, receiveValue: { (aluno) in
			alunos.append(aluno)
			if alunos.count >= 2 {
				expectativa.fulfill()
			}
		})

		self.waitForExpectations(timeout: 1.0)

		// then
		XCTAssert(alunos.contains(provedorTeste.aluno3))
		XCTAssert(alunos.contains(provedorTeste.aluno4))

		// teardown
		cancelavel.cancel()
	}

	func testarBuscaTodos() {
		// given
		let expectativa = expectation(description: "Todos os Alunos")
		let provedorTeste = ProvedorTeste(teste: .ambos)

		var alunos = [Aluno]()

		// when
		let controleAluno = ControleAluno(preferencias: preferenciasTeste, provedorAluno: provedorTeste)
		let cancelavel = controleAluno.sink(receiveCompletion: cuidarDoErro, receiveValue: { (aluno) in
			alunos.append(aluno)
			if alunos.count >= 4 {
				expectativa.fulfill()
			}
		})

		self.waitForExpectations(timeout: 1.0)

		// then
		XCTAssert(alunos.contains(provedorTeste.aluno1))
		XCTAssert(alunos.contains(provedorTeste.aluno2))
		XCTAssert(alunos.contains(provedorTeste.aluno3))
		XCTAssert(alunos.contains(provedorTeste.aluno4))

		// teardown
		cancelavel.cancel()
	}
}
