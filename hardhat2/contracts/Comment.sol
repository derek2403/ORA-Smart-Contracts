// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./interfaces/IAIOracle.sol";
import "./AIOracleCallbackReceiver.sol";

contract Comment is AIOracleCallbackReceiver {

    event commentEvaluation(
        uint256 requestId,
        uint256 modelId,
        string input,
        string output,
        bytes callbackData
    );

    event commentEvaluationRequest(
        uint256 requestId,
        address sender, 
        uint256 modelId,
        string comment
    );

    struct AIOracleRequest {
        address sender;
        uint256 modelId;
        bytes input;
        bytes output;
    }

    address public owner;

    mapping(uint256 => AIOracleRequest) public requests;
    mapping(uint256 => uint64) public callbackGasLimit;
    mapping(uint256 => mapping(string => string)) public commentEvaluations;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    constructor(IAIOracle _aiOracle) AIOracleCallbackReceiver(_aiOracle) {
        owner = msg.sender;
        callbackGasLimit[11] = 5_000_000; // Llama model for comment evaluations
    }

    function getCommentEvaluation(uint256 modelId, string calldata comment) external view returns (string memory) {
        return commentEvaluations[modelId][comment];
    }

    function aiOracleCallback(uint256 requestId, bytes calldata output, bytes calldata callbackData) external override onlyAIOracleCallback() {
        AIOracleRequest storage request = requests[requestId];
        require(request.sender != address(0), "request does not exist");
        request.output = output;
        commentEvaluations[request.modelId][string(request.input)] = string(output);
        emit commentEvaluation(requestId, request.modelId, string(request.input), string(output), callbackData);
    }

    function estimateFee(uint256 modelId) public view returns (uint256) {
        return aiOracle.estimateFee(modelId, callbackGasLimit[modelId]);
    }

    function evaluateComment(
        uint256 modelId,
        string calldata comment
    ) payable external {
        require(msg.value >= aiOracle.estimateFee(modelId, callbackGasLimit[modelId]), "Insufficient fee");

        string memory promptInstruction = string(abi.encodePacked(
            "Evaluate the following customer comment based on these criteria: food, service, price, speed of delivery, menu options, and promotions. ",
            "Each mentioned criterion contributes 8.33% to the score. Calculate the final percentage score using this formula: 50 + (8.33 * number of criteria mentioned). ",
            "Only output the final percentage value, nothing else. Here's the comment to evaluate: '",
            comment,
            "'"
        ));

        bytes memory input = bytes(promptInstruction);
        bytes memory callbackData = bytes("");
        address callbackAddress = address(this);

        try aiOracle.requestCallback{value: msg.value}(
            modelId, input, callbackAddress, callbackGasLimit[modelId], callbackData
        ) returns (uint256 requestId) {
            AIOracleRequest storage request = requests[requestId];
            request.input = input;
            request.sender = msg.sender;
            request.modelId = modelId;

            emit commentEvaluationRequest(requestId, msg.sender, modelId, comment);
        } catch Error(string memory reason) {
            revert(string(abi.encodePacked("AIOracle request failed: ", reason)));
        } catch (bytes memory lowLevelData) {
            revert("AIOracle request failed with unknown error");
        }
    }
}