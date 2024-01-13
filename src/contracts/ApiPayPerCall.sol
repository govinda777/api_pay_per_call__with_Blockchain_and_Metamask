// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";

contract ApiPayPerCall is ChainlinkClient {
    using Chainlink for Chainlink.Request;

    // Definindo a taxa de serviço
    uint256 public serviceFee;
    // Endereço do operador Chainlink (Oracle)
    address private oracle;
    // Job ID para a chamada de API
    bytes32 private jobId;
    // LINK token
    uint256 private fee;

    // Eventos
    event RequestFulfilled(bytes32 indexed requestId, uint256 indexed statusCode, string indexed response);

    // Construtor
    constructor(uint256 _serviceFee, address _oracle, bytes32 _jobId, uint256 _fee) {
        setPublicChainlinkToken();
        serviceFee = _serviceFee;
        oracle = _oracle;
        jobId = _jobId;
        fee = _fee;
    }

    // Função para receber e processar a chamada
    function callAPI(string memory url) public payable {
        require(msg.value >= serviceFee, "Not enough Ether sent for service fee");
        
        Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);

        // Definindo a URL e o caminho para a resposta da API
        request.add("get", url);
        request.add("path", "data.path.to.response");

        // Enviando a requisição e retornando o ID da requisição
        sendChainlinkRequestTo(oracle, request, fee);

        // Devolver o troco, se houver
        if (msg.value > serviceFee) {
            payable(msg.sender).transfer(msg.value - serviceFee);
        }
    }

    // Função de callback para o Chainlink
    function fulfill(bytes32 requestId, uint256 statusCode, string memory response) public recordChainlinkFulfillment(requestId) {
        emit RequestFulfilled(requestId, statusCode, response);
    }

    // Função para retirar LINK do contrato (se necessário)
    function withdrawLink() external {
        require(LINK.transfer(msg.sender, LINK.balanceOf(address(this))), "Unable to transfer");
    }
}
